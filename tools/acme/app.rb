require "base64"
require "cgi"
require "digest"
require "json"
require "net/http"
require "openssl"
require "securerandom"
require "time"
require "uri"
require "jwt"
require "rack"

module Acme
  class App
    PLATFORM_ISSUER = ENV.fetch("LTI_PLATFORM_ISSUER", "http://127.0.0.1:3000").delete_suffix("/")
    CLIENT_ID = ENV.fetch("LTI_TOOL_CLIENT_ID", "acme-guess-the-number")
    DEPLOYMENT_ID = ENV.fetch("LTI_DEPLOYMENT_ID", "local-acme")
    TOOL_BASE_URL = ENV.fetch("LTI_TOOL_BASE_URL", "http://127.0.0.1:3002").delete_suffix("/")
    AGS_SCORE_SCOPE = "https://purl.imsglobal.org/spec/lti-ags/scope/score"
    KEY_ID = "acme-tool-key"

    def initialize(platform_issuer: PLATFORM_ISSUER, client_id: CLIENT_ID, deployment_id: DEPLOYMENT_ID,
      tool_base_url: TOOL_BASE_URL, private_key: load_private_key, jwks_fetcher: nil, score_submitter: nil)
      @platform_issuer = platform_issuer.delete_suffix("/")
      @client_id = client_id
      @deployment_id = deployment_id
      @tool_base_url = tool_base_url.delete_suffix("/")
      @private_key = private_key
      @jwks_fetcher = jwks_fetcher || method(:fetch_platform_jwks)
      @score_submitter = score_submitter || method(:submit_score)
      @state_secret = OpenSSL::Digest::SHA256.digest(@private_key.to_der)
      @games = {}
      @used_states = {}
      @mutex = Mutex.new
    end

    def call(env)
      request = Rack::Request.new(env)
      case [request.request_method, request.path_info]
      when ["GET", "/health"]
        response(200, "ok", "text/plain")
      when ["GET", "/.well-known/jwks.json"]
        json_response(200, "keys" => [public_jwk])
      when ["GET", "/lti/login"]
        initiate_login(request)
      when ["POST", "/lti/launch"]
        receive_launch(request)
      when ["GET", "/game"]
        show_game(request)
      when ["POST", "/guess"]
        guess(request)
      when ["POST", "/report"]
        retry_report(request)
      else
        response(404, "Not found")
      end
    rescue LaunchError => error
      response(error.status, html_page("Unable to launch Guess the Number", "<p>#{h(error.message)}</p>"))
    end

    private

    def initiate_login(request)
      params = request.params
      unless params["iss"] == @platform_issuer &&
          params["client_id"] == @client_id &&
          params["target_link_uri"] == launch_url &&
          !params["login_hint"].to_s.empty?
        return response(400, html_page("Invalid LTI login", "<p>The LMS sent an invalid login request.</p>"))
      end

      nonce = SecureRandom.urlsafe_base64(32)
      state = signed_state(nonce)
      authorization_uri = URI("#{@platform_issuer}/lti/authorize")
      authorization_uri.query = URI.encode_www_form(
        client_id: @client_id,
        redirect_uri: launch_url,
        response_type: "id_token",
        scope: "openid",
        response_mode: "form_post",
        prompt: "none",
        state: state,
        nonce: nonce,
        login_hint: params["login_hint"]
      )
      redirect(authorization_uri.to_s)
    end

    def receive_launch(request)
      state = request.params["state"]
      nonce = nonce_from_state(state)
      token = request.params["id_token"]
      raise LaunchError.new("The LMS launch is missing required data.", 400) unless nonce && token

      claims = validate_id_token(token, nonce)
      consume_state!(state)
      session_id = SecureRandom.urlsafe_base64(32)
      game = {
        secret: rand(1..100),
        attempts: 0,
        solved: false,
        reported: false,
        created_at: Time.now,
        last_message: "I'm thinking of a number between 1 and 100.",
        user_id: claims.fetch("sub"),
        return_url: claims.dig("https://purl.imsglobal.org/spec/lti/claim/launch_presentation", "return_url"),
        lineitem: ags_lineitem(claims)
      }
      @mutex.synchronize do
        prune_expired_sessions
        @games[session_id] = game
      end

      [
        303,
        {
          "Location" => "/game",
          "Set-Cookie" => "acme_game=#{session_id}; Path=/; HttpOnly; SameSite=Lax",
          "Content-Type" => "text/html; charset=utf-8"
        },
        []
      ]
    rescue JWT::DecodeError, KeyError, JSON::ParserError, URI::InvalidURIError => error
      warn "Rejected LTI launch: #{error.class}: #{error.message}"
      raise LaunchError.new("The LMS launch could not be validated.", 401)
    end

    def show_game(request)
      game = game_for(request)
      return response(401, html_page("Launch required", "<p>Open this activity from your LMS course.</p>")) unless game

      response(200, game_page(game))
    end

    def guess(request)
      game = game_for(request)
      return response(401, html_page("Launch required", "<p>Open this activity from your LMS course.</p>")) unless game

      if game[:solved]
        report_completion(game)
        return response(200, game_page(game))
      end

      guess = Integer(request.params["guess"], 10)
      unless (1..100).cover?(guess)
        game[:last_message] = "Enter a whole number from 1 to 100."
        return response(422, game_page(game))
      end

      game[:attempts] += 1
      if guess == game[:secret]
        game[:solved] = true
        game[:last_message] = "Correct! You solved it in #{game[:attempts]} #{guess_word(game[:attempts])}."
        report_completion(game)
      elsif guess < game[:secret]
        game[:last_message] = "Too low. Try a higher number."
      else
        game[:last_message] = "Too high. Try a lower number."
      end

      response(200, game_page(game))
    rescue ArgumentError, TypeError
      game[:last_message] = "Enter a whole number from 1 to 100."
      response(422, game_page(game))
    end

    def retry_report(request)
      game = game_for(request)
      return response(401, html_page("Launch required", "<p>Open this activity from your LMS course.</p>")) unless game
      return response(409, game_page(game)) unless game[:solved]

      report_completion(game)
      response(200, game_page(game))
    end

    def report_completion(game)
      return if game[:reported]

      comment = "Solved in #{game[:attempts]} #{guess_word(game[:attempts])}"
      @score_submitter.call(game.fetch(:lineitem), game.fetch(:user_id), game.fetch(:attempts), comment)
      game[:reported] = true
      game[:report_error] = nil
    rescue Net::OpenTimeout, Net::ReadTimeout, SocketError, SystemCallError, IOError, JSON::ParserError => error
      game[:report_error] = "The LMS could not be reached to save your result (#{error.class}). You can retry."
    rescue LaunchError => error
      game[:report_error] = error.message
    end

    def validate_id_token(token, expected_nonce)
      unverified_payload, header = JWT.decode(token, nil, false)
      key = platform_public_key(header["kid"])
      claims, verified_header = JWT.decode(token, key, true, algorithms: ["RS256"])
      now = Time.now.to_i
      lti = "https://purl.imsglobal.org/spec/lti/claim/"
      ags = "https://purl.imsglobal.org/spec/lti-ags/claim/endpoint"

      unless verified_header["kid"] == header["kid"] &&
          claims["iss"] == @platform_issuer &&
          audience_matches?(claims) &&
          claims["nonce"] == expected_nonce &&
          claims["exp"].is_a?(Integer) && claims["exp"] > now && claims["exp"] <= now + 600 &&
          claims["iat"].is_a?(Integer) && claims["iat"] <= now + 30 && claims["iat"] >= now - 600 &&
          !claims["sub"].to_s.empty? &&
          claims["#{lti}deployment_id"] == @deployment_id &&
          claims["#{lti}message_type"] == "LtiResourceLinkRequest" &&
          claims["#{lti}version"] == "1.3.0" &&
          claims["#{lti}target_link_uri"] == launch_url &&
          claims.dig(ags, "scope").to_a.include?(AGS_SCORE_SCOPE) &&
          !claims.dig("#{lti}resource_link", "id").to_s.empty? &&
          !claims.dig("#{lti}context", "id").to_s.empty?
        raise JWT::DecodeError, "LTI claims did not match the registration."
      end

      claims
    rescue KeyError
      raise JWT::DecodeError, "The LTI launch is missing required claims."
    end

    def audience_matches?(claims)
      audience = claims["aud"]
      (audience == @client_id || audience.is_a?(Array) && audience.include?(@client_id)) &&
        (claims["azp"].nil? || claims["azp"] == @client_id)
    end

    def platform_public_key(kid)
      jwks = @jwks_fetcher.call
      jwk = jwks.fetch("keys").find do |key|
        key["kid"] == kid && key["kty"] == "RSA" && key["use"] == "sig"
      end
      raise JWT::DecodeError, "Unknown LMS signing key." unless jwk

      JWT::JWK.import(jwk).public_key
    end

    def fetch_platform_jwks
      uri = URI("#{@platform_issuer}/lti/jwks")
      response = Net::HTTP.start(uri.host, uri.port, open_timeout: 2, read_timeout: 2) do |http|
        http.get(uri.request_uri)
      end
      raise LaunchError.new("The LMS key endpoint returned HTTP #{response.code}.", 503) unless response.is_a?(Net::HTTPSuccess)

      JSON.parse(response.body)
    rescue JSON::ParserError, KeyError => error
      raise JWT::DecodeError, "Invalid LMS JWKS: #{error.message}"
    end

    def ags_lineitem(claims)
      endpoint = claims.fetch("https://purl.imsglobal.org/spec/lti-ags/claim/endpoint").fetch("lineitem")
      uri = URI(endpoint)
      issuer = URI(@platform_issuer)
      unless uri.scheme == issuer.scheme && uri.host == issuer.host && uri.port == issuer.port &&
          uri.path.start_with?("/lti/ags/line_items/") && uri.query.nil?
        raise JWT::DecodeError, "Invalid AGS line item URL."
      end

      endpoint
    end

    def submit_score(lineitem, user_id, attempts, comment)
      raise LaunchError.new("Cannot submit a result with no valid guesses.", 422) unless attempts.to_i.positive?

      token = obtain_access_token
      uri = URI("#{lineitem}/scores")
      body = {
        userId: user_id,
        scoreGiven: 100,
        scoreMaximum: 100,
        comment: comment,
        timestamp: Time.now.utc.iso8601,
        activityProgress: "Completed",
        gradingProgress: "FullyGraded"
      }
      http = Net::HTTP.new(uri.host, uri.port)
      http.open_timeout = 2
      http.read_timeout = 2
      response = http.post(uri.request_uri, JSON.generate(body), {
        "Authorization" => "Bearer #{token}",
        "Content-Type" => "application/vnd.ims.lis.v1.score+json"
      })
      raise LaunchError.new("The LMS rejected the AGS score (HTTP #{response.code}).", 502) unless
        response.is_a?(Net::HTTPSuccess) || response.code.to_i == 204
    end

    def obtain_access_token
      assertion = JWT.encode(
        {
          iss: @client_id,
          sub: @client_id,
          aud: "#{@platform_issuer}/lti/oauth/token",
          iat: Time.now.to_i,
          exp: Time.now.to_i + 60,
          jti: SecureRandom.uuid
        },
        @private_key,
        "RS256",
        { kid: KEY_ID }
      )
      uri = URI("#{@platform_issuer}/lti/oauth/token")
      http = Net::HTTP.new(uri.host, uri.port)
      http.open_timeout = 2
      http.read_timeout = 2
      response = http.post(uri.request_uri, URI.encode_www_form({
        grant_type: "client_credentials",
        client_assertion_type: "urn:ietf:params:oauth:client-assertion-type:jwt-bearer",
        client_assertion: assertion,
        scope: AGS_SCORE_SCOPE
      }), { "Content-Type" => "application/x-www-form-urlencoded" })
      raise LaunchError.new("The LMS rejected the AGS token request (HTTP #{response.code}).", 502) unless response.is_a?(Net::HTTPSuccess)

      JSON.parse(response.body).fetch("access_token")
    end

    def signed_state(nonce)
      payload = Base64.urlsafe_encode64(JSON.generate(
        nonce: nonce,
        exp: Time.now.to_i + 300,
        target: launch_url,
        jti: SecureRandom.hex(16)
      ), padding: false)
      "#{payload}.#{OpenSSL::HMAC.hexdigest('SHA256', @state_secret, payload)}"
    end

    def nonce_from_state(state)
      encoded, signature = state.to_s.split(".", 2)
      return unless encoded && signature

      expected = OpenSSL::HMAC.hexdigest("SHA256", @state_secret, encoded)
      return unless Rack::Utils.secure_compare(signature, expected)

      payload = JSON.parse(Base64.urlsafe_decode64(encoded))
      return unless payload["target"] == launch_url && payload["exp"].to_i > Time.now.to_i &&
        payload["exp"].to_i <= Time.now.to_i + 300 && !payload["nonce"].to_s.empty?
      return if @mutex.synchronize { @used_states.key?(Digest::SHA256.hexdigest(state)) }

      payload["nonce"]
    rescue ArgumentError, JSON::ParserError
      nil
    end

    def consume_state!(state)
      digest = Digest::SHA256.hexdigest(state)
      @mutex.synchronize do
        raise LaunchError.new("This LTI login request has already been used.", 401) if @used_states.key?(digest)

        @used_states[digest] = Time.now.to_i + 300
      end
    end

    def game_for(request)
      id = request.cookies["acme_game"]
      return unless id && id.match?(/\A[A-Za-z0-9_-]{32,64}\z/)

      @mutex.synchronize { @games[id] }
    end

    def prune_expired_sessions
      cutoff = Time.now - 3600
      @games.delete_if { |_id, game| game[:created_at] < cutoff }
      @used_states.delete_if { |_id, expires_at| expires_at < Time.now.to_i }
    end

    def game_page(game)
      content = <<~HTML
        <main class="panel">
          <p class="muted">Acme · Guess the Number</p>
          <h1>Guess the Number</h1>
          <p role="status">#{h(game[:last_message])}</p>
          <p>Guesses: #{game[:attempts]}</p>
          #{guess_form(game)}
          #{report_status(game)}
          <p><a href="#{h(game[:return_url])}">Return to course</a></p>
        </main>
      HTML
      html_page("Guess the Number", content)
    end

    def guess_form(game)
      return "" if game[:solved]

      <<~HTML
        <form method="post" action="/guess">
          <label for="guess">Your guess (1–100)</label>
          <input id="guess" name="guess" type="number" min="1" max="100" step="1" required autofocus>
          <button type="submit">Guess</button>
        </form>
      HTML
    end

    def report_status(game)
      return "<p class=\"status\">Result sent to the LMS.</p>" if game[:reported]
      return "" unless game[:solved]

      <<~HTML
        <p class="alert" role="alert">#{h(game[:report_error] || "Saving your result to the LMS failed.")}</p>
        <form method="post" action="/report"><button type="submit">Retry saving result</button></form>
      HTML
    end

    def guess_word(count)
      count == 1 ? "guess" : "guesses"
    end

    def public_jwk
      JWT::JWK.new(@private_key, kid: KEY_ID).export.merge(use: "sig", alg: "RS256")
    end

    def launch_url
      "#{@tool_base_url}/lti/launch"
    end

    def load_private_key
      default_path = File.expand_path("../../.local/lti/acme-tool.pem", __dir__)
      path = ENV.fetch("LTI_TOOL_PRIVATE_KEY_PATH", default_path)
      raise "LTI tool key is missing at #{path}; run ./dev start to generate local keys." unless File.file?(path)

      OpenSSL::PKey::RSA.new(File.read(path))
    end

    def redirect(location)
      [303, { "Location" => location, "Content-Type" => "text/html; charset=utf-8" }, []]
    end

    def json_response(status, object)
      response(status, JSON.generate(object), "application/json")
    end

    def response(status, body, content_type = "text/html")
      [status, { "Content-Type" => "#{content_type}; charset=utf-8" }, [body]]
    end

    def html_page(title, content)
      <<~HTML
        <!doctype html>
        <html lang="en">
          <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <title>#{h(title)}</title>
            <style>
              body { margin: 2rem auto; padding: 0 1rem; max-width: 42rem; font: 1rem/1.5 system-ui, sans-serif; color: #17212b; }
              .panel { padding: 1.5rem; border: 1px solid #ccd5de; border-radius: .5rem; }
              .muted { color: #526170; } .status { color: #17613a; } .alert { color: #9c2c24; }
              input, button { margin: .4rem 0; padding: .6rem; font: inherit; }
            </style>
          </head>
          <body>#{content}</body>
        </html>
      HTML
    end

    def h(value)
      CGI.escapeHTML(value.to_s)
    end

    class LaunchError < StandardError
      attr_reader :status

      def initialize(message, status)
        super(message)
        @status = status
      end
    end
  end
end

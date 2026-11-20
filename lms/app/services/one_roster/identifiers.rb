require "digest"

module OneRoster
  module Identifiers
    # Derive stable OneRoster IDs for generated gradebook records so repeated
    # syncs refer to the same results instead of creating duplicates.
    def self.uuid_v5(namespace_uuid, name)
      namespace = [namespace_uuid.delete("-")].pack("H*")
      bytes = Digest::SHA1.digest(namespace + name).bytes.first(16)
      bytes[6] = (bytes[6] & 0x0f) | 0x50
      bytes[8] = (bytes[8] & 0x3f) | 0x80
      hex = bytes.pack("C*").unpack1("H*")
      "#{hex[0, 8]}-#{hex[8, 4]}-#{hex[12, 4]}-#{hex[16, 4]}-#{hex[20, 12]}"
    end
  end
end

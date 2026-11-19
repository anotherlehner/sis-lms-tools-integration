#!/usr/bin/env ruby

system("bin/rails", "db:reset")
exit 1 unless $?.success?

#!/usr/bin/env ruby

system("bin/rails", "db:migrate")
exit 1 unless $?.success?

#!/usr/bin/env ruby

system("bin/rails", "db:create")
exit 1 unless $?.success?
system("bin/rails", "db:migrate")
exit 1 unless $?.success?
system("bin/rails", "db:seed")
exit 1 unless $?.success?

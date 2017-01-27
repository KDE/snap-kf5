#!/usr/bin/env ruby
# frozen_string_literal: true
#
# Copyright (C) 2017 Harald Sitter <sitter@kde.org>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) version 3, or any
# later version accepted by the membership of KDE e.V. (or its
# successor approved by the membership of KDE e.V.), which shall
# act as a proxy defined in Section 6 of version 3 of the license.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library.  If not, see <http://www.gnu.org/licenses/>.

require 'json'

# For each part build a list of all packages that snapcraft would have put into
# the part, then expand the existing content lists with the recursive listing.
# This allows stricter staging in apps as they will know ALL packages in the
# content share (so long as they came from snapcraft anyway).

PARTS_FILE_MAP = {
  'kf5' => 'stage-content.json',
  'kf5-dev' => 'stage-dev.json'
}.freeze

PARTS_FILE_MAP.each do |part, file|
  pkgs = Dir.glob("parts/#{part}/ubuntu/download/*.deb").collect do |debfile|
    debfile = File.basename(debfile)
    match = debfile.match(/^(.+)_([^_]+)_([^_]+)\.deb$/) || raise
    match[1] # Package name
  end
  raise "couldn't find packages of #{part}" if pkgs.empty?
  pkgs += JSON.parse(File.read(file))
  JSON.write(file, pkgs.uniq.compact)
end

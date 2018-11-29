#!/usr/bin/env ruby
# frozen_string_literal: true
#
# Copyright (C) 2018 Harald Sitter <sitter@kde.org>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of
# the License or any later version accepted by the membership of
# KDE e.V. (or its successor approved by the membership of KDE
# e.V.), which shall act as a proxy defined in Section 14 of
# version 3 of the license.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

require 'fileutils'
require 'tmpdir'

require 'tty/command'

configs = []
Dir.chdir('usr/lib/x86_64-linux-gnu/cmake/') do
  Dir.glob('*/*Config.cmake').each do |config_file|
    config = config_file.split('/')[-1]
    configs << config.sub('Config.cmake', '')
  end
end

wrapped_exes = []

configs.each do |config|
  warn "config... #{config}"
  Dir.mktmpdir do |tmpdir|
    File.write("#{tmpdir}/CMakeLists.txt", <<-EOF)
cmake_minimum_required(VERSION 3.0)

set(imported_exec_targets)
macro(add_executable)
    message("args ${ARGN}")
    set(args "${ARGN}")
    list(FIND args "IMPORTED" is_imported)
    # Don't use IN_LIST so we don't have to meddle with policies.
    if(is_imported GREATER -1)
        list(LENGTH args len)
        list(GET args 0 name)
        list(APPEND imported_exec_targets ${name})
        message("  is imported ${name}")
    endif()
    _add_executable(${ARGN})
endmacro()

find_package(#{config} REQUIRED NO_MODULE)

file(WRITE "${CMAKE_BINARY_DIR}/import.txt" "")
message("imported_exec_targets ${imported_exec_targets}")
# IMPORTED_LOCATION_DEBIAN
foreach(target IN LISTS imported_exec_targets)
    get_target_property(location ${target} IMPORTED_LOCATION)
    if(NOT location)
        get_target_property(configs ${target} IMPORTED_CONFIGURATIONS)
        foreach(config IN LISTS configs)
            message("t: ${target} ... trying config ${config}")
            get_target_property(location ${target} "IMPORTED_LOCATION_${config}")
        endforeach()
    endif()
    message("t: ${target} => ${location}")
    message("======================")
    file(APPEND "${CMAKE_BINARY_DIR}/import.txt" "${location};")
#   print_target_properties(${target})
endforeach()
EOF

    # TODO: bugged https://phabricator.kde.org/D17234
    next if config.downcase.include?('notifyconfig')
    # meta configs, not to be run without components
    next if config.downcase == 'qt5'
    next if config.downcase == 'kf5'

    cmd = TTY::Command.new
    # FIXME: probably best to ignore errors, or log them somewhere but continue all the same
    cmd.run('cmake', '.', "-DCMAKE_FIND_ROOT_PATH=#{Dir.pwd}", chdir: tmpdir)

    exes = File.read("#{tmpdir}/import.txt").strip.split(';')
    exes.each do |exe|
      warn "exe... #{exe}"
      # FIXME: maybe realname it first, in case there's a symlink?
      next if wrapped_exes.include?(exe)

      basename = File.basename(exe)
      FileUtils.mv(exe, "#{exe}.orig", verbose: true)

      File.write(exe, <<-EOF)
#!/bin/bash

export LD_LIBRARY_PATH=/snap/kde-frameworks-5-core18/current/usr/lib/x86_64-linux-gnu:/snap/kde-frameworks-5-core18/current/usr/lib:${LD_LIBRARY_PATH}
exec $(dirname "$0")/#{basename}.orig "$@"
      EOF
      FileUtils.chmod(0o0755, exe, verbose: true)

      wrapped_exes << exe
    end
  end
end

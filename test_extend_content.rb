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

require 'minitest/autorun'

require 'fileutils'
require 'tmpdir'

require_relative 'extend_content'

class TestExtendContent < Minitest::Test
  def setup
    @tmpdir = Dir.mktmpdir
    Dir.chdir(@tmpdir)
  end

  def teardown
    FileUtils.rm_rf(@tmpdir)
  end

  def test_extend
    FileUtils.mkpath('parts/kf5/ubuntu/download')
    FileUtils.touch('parts/kf5/ubuntu/download/foo_bar_1.0_amd64.deb')
    FileUtils.touch('parts/kf5/ubuntu/download/meow_1_amd64.deb')
    FileUtils.mkpath('parts/kf5-dev/ubuntu/download')
    FileUtils.touch('parts/kf5-dev/ubuntu/download/kitteh_1_amd64.deb')

    File.write('stage-content.json', JSON.generate(%w(a)))
    File.write('stage-dev.json', JSON.generate(%w(b)))

    Content.extend

    data = JSON.parse(File.read('stage-content.json'))
    assert_equal(%w(foo_bar meow a).sort, data.sort)

    data = JSON.parse(File.read('stage-dev.json'))
    assert_equal(%w(b kitteh).sort, data.sort)
  end
end

# frozen_string_literal: true

# Copyright (c) [2022] SUSE LLC
#
# All Rights Reserved.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of version 2 of the GNU General Public License as published
# by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, contact SUSE LLC.
#
# To contact SUSE LLC about this file by physical or electronic mail, you may
# find current contact information at www.suse.com.

require_relative "../test_helper"
require "dinstaller/dbus/service"
require "dinstaller/manager"

describe DInstaller::DBus::Service do
  subject(:service) { described_class.new(manager, logger) }

  let(:logger) { Logger.new($stdout) }
  let(:manager) { DInstaller::Manager.new(logger) }
  let(:bus) { instance_double(::DBus::SystemBus) }
  let(:bus_service) do
    instance_double(::DBus::Service, export: nil)
  end

  before do
    allow(::DBus::SystemBus).to receive(:instance).and_return(bus)
    allow(bus).to receive(:request_service).and_return(bus_service)
  end

  describe "#export" do
    it "exports the language manager object" do
      language_obj = instance_double(DInstaller::DBus::Language, path: nil)
      allow(DInstaller::DBus::Language).to receive(:new)
        .with(manager.language, logger).and_return(language_obj)

      expect(bus_service).to receive(:export).with(language_obj)
      service.export
    end

    it "exports the software manager object" do
      software_obj = instance_double(DInstaller::DBus::Software, path: nil)
      allow(DInstaller::DBus::Software).to receive(:new)
        .with(manager.software, logger).and_return(software_obj)

      expect(bus_service).to receive(:export).with(software_obj)
      service.export
    end

    it "exports the storage actions object" do
      actions_obj = instance_double(DInstaller::DBus::Storage::Actions, path: nil)
      allow(DInstaller::DBus::Storage::Actions).to receive(:new)
        .with(manager.storage.actions, logger).and_return(actions_obj)

      expect(bus_service).to receive(:export).with(actions_obj)
      service.export
    end

    it "exports the storage proposal object" do
      proposal_obj = instance_double(DInstaller::DBus::Storage::Proposal, path: nil)
      allow(DInstaller::DBus::Storage::Proposal).to receive(:new)
        .with(manager.storage.proposal, DInstaller::DBus::Storage::Actions, logger)
        .and_return(proposal_obj)

      expect(bus_service).to receive(:export).with(proposal_obj)
      service.export
    end

    it "exports the users manager object" do
      users_obj = instance_double(DInstaller::DBus::Users, path: nil)
      allow(DInstaller::DBus::Users).to receive(:new)
        .with(manager.users, logger).and_return(users_obj)

      expect(bus_service).to receive(:export).with(users_obj)
      service.export
    end
  end

  describe "#dispatch" do
    it "dispatches the messages from the bus" do
      expect(bus).to receive(:dispatch_message_queue)
      service.dispatch
    end
  end
end
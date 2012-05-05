require 'spec_helper'
include Brassbound

class Account
  def self.find(account_id)
    case account_id
    when 1
      Account.new(200)
    when 2
      Account.new(100)
    end
  end

  attr_accessor :balance

  def initialize(balance)
    @balance = balance
  end
end

module MoneySource
  def transfer_out(amount)
    self.balance -= amount
    context.dest_account.transfer_in(amount)
  end
end

module MoneySink
  def transfer_in(amount)
    self.balance += amount
  end
end

class TransferFunds
  include Context

  def initialize(source_account_id, dest_account_id, amount)
    @source_account_id = source_account_id
    @dest_account_id = dest_account_id
    @amount = amount

    role :source_account, MoneySource, Account.find(@source_account_id)
    role :dest_account, MoneySink, Account.find(@dest_account_id)
  end

  def execute
    source_account.transfer_out(@amount)
    # Allow spec to access the executing context for testing
    yield self if block_given?
  end
end

describe Context do
  include Context

  let(:source_account_id) { 1 }
  let(:dest_account_id) { 2 }
  let(:source_account) { Account.find(source_account_id) }
  let(:dest_account) { Account.find(dest_account_id) }

  let(:transfer_funds_context) {
    TransferFunds.new(source_account_id, dest_account_id, 50)
  }

  context "#role" do
    it "declares a role mapping" do
      role MoneySource, source_account
      mapping = roles[:money_source]
      mapping.role_module.should == MoneySource
      mapping.data_object.should == source_account

      role :money_sink, MoneySink, dest_account
      mapping = roles[:money_sink]
      mapping.role_module.should == MoneySink
      mapping.data_object.should == dest_account
    end
  end

  context "#call" do
    it "binds all roles to their mapped objects" do
      transfer_funds_context.call do |ctx|
        ctx.source_account.should == source_account
        ctx.source_account.should be_kind_of(MoneySource)
        ctx.dest_account.should == dest_account
        ctx.dest_account.should be_kind_of(MoneySink)
      end
    end
  end
end


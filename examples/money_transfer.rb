require 'brassbound'

# Domain/data objects are plain old Ruby objects.
class Account
  # Pretend to lookup accounts in a database.
  def self.find(account_id)
    case account_id
    when 1
      Account.new(account_id, 2000)
    when 2
      Account.new(account_id, 1000)
    end
  end

  attr_reader   :id
  attr_accessor :balance

  def initialize(id, balance)
    @id = id
    @balance = balance
  end
end

# Roles are plain old Ruby modules, and automatically have access to
# the invoking context.
module MoneySource
  def transfer_out(amount)
    puts("Transferring #{amount} from account #{self.id} to account #{context.money_sink.id}")
    self.balance -= amount
    puts("Source account new balance: #{self.balance}")
    context.money_sink.transfer_in(amount)
  end
end

module MoneySink
  def transfer_in(amount)
    self.balance += amount
    puts("Destination account new balance: #{self.balance}")
  end
end

# Contexts are Ruby classes that include the Brassbound::Context module.
# The common idiom is for the initialize method to create all of the
# necessary objects and declare how they are bound to roles.
# Then, within the scope of the execute method, the objects will have been
# bound to the declared roles, and can be accessed by the role name
# (convert to lower case with underscores by default).
class TransferFunds
  include Brassbound::Context

  def initialize(source_account_id, dest_account_id, amount)
    @amount = amount

    role MoneySource, Account.find(source_account_id)
    role MoneySink, Account.find(dest_account_id)
  end

  def execute
    # Here, money_source refers to the object bound to the MoneySource role
    # in the initialize method.
    money_source.transfer_out(@amount)
  end
end

# Now let's create and execute our context.
TransferFunds.new(1, 2, 100).call


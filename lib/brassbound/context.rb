# This module represents the notion of the Context in the DCI paradigm.
#
# According to http://en.wikipedia.org/wiki/Data,_context_and_interaction
#
#   The Context is the class (or its instance) whose code includes the roles
#   for a given algorithm, scenario, or use case, as well as the code to map
#   these roles into objects at run time and to enact the use case. Each role
#   is bound to exactly one object during any given use case enactment; however,
#   a single object may simultaneously play several roles. A context is
#   instantiated at the beginning of the enactment of an algorithm, scenario,
#   or use case. In summary, a Context comprises use cases and algorithms in
#   which data objects are used through specific Roles.
#
# In Brassbound, context implementations are classes that include this module.
# Context implementations can use the #role method to bind roles to objects,
# and must provide an #execute method that enacts the use case behavior.
#
# Brassbound enforces the fact that each role is bound to exactly one object,
# since each role must have a unique name. However, any given object may
# simultaneously play several roles.
#
# Note that no special support is required for the role module or data object
# implementations; they are normal Ruby modules and objects, respectively.
# The context manages the necessary plumbing to bind roles to objects and to
# provide access to the context for the roles. In other words, role modules do
# not have to include any other modules or adhere to any particular conventions,
# and neither do the objects to which the roles are bound need to inherit from
# any other class or include any other modules.
module Brassbound::Context

  require 'brassbound/util'

  # The currently executing context. Stored as a thread-local variable, so
  # each thread can have its own current context.
  def self.current
    Thread.current[:brassbound_context]
  end

  # A Hash containing all of the declared role mappings for this context.
  # The keys of the Hash are the declared role names, while the values
  # are the associated RoleMapping objects.
  #
  # Role mappings are declared using the #role method, which see for
  # further details.
  def roles
    @declared_roles ||= Hash.new
  end

  # Declare a role mapping.
  #
  # This method accepts either two or three arguments. In the three argument
  # form, the arguments are as follows:
  #
  #   role_name:: The name of the role in this context.
  #   role_module:: The module that serves as the "methodful role".
  #   obj:: The data object to which the role_module will be attached.
  #
  # In the two argument form, the role_name is omitted and the role_name
  # is derived from the name of the role_module by converting from
  # CamelCaseName to underscore_name. For instance, if the role_name
  # is not specified, then a role_module called MoneySource would be
  # named money_source.
  #
  # This method adds the role mapping to the Hash returned by the #roles
  # method. If the context is already executing when this method is
  # invoked, it will call #apply_role to reify the role mapping
  # immediately. Otherwise, all role mappings are applied when the
  # context begins execution.
  def role(*args)
    case args.size
    when 2
      role_module = args[0]
      obj = args[1]
      role_name = Util.underscore(role_module.name).to_sym
    when 3
      role_name = args[0]
      role_module = args[1]
      obj = args[2]
    else
      raise ArgumentError
    end

    self.roles[role_name] = RoleMapping.new(role_module, obj)

    if ::Brassbound::Context.current.equal?(self)
      # If we are already in the execute method, apply the role mapping.
      apply_role(role_name)
    end
  end

  # Apply the role identified by role_name to the associated object.
  # This has several effects. First, the object is extended with the
  # role module (i.e. the "methodful role" in DCI terminology), thus
  # adding all of the role module's methods to the object. Second,
  # the object has a :context method added to it, which provides
  # the role implementation access to this context. Finally, a new
  # method is added to this context object, which is named after the
  # role_name and which returns the object which is mapped to that role.
  def apply_role(role_name)
    role_mapping = self.roles[role_name]
    role_module, obj = role_mapping.role_module, role_mapping.data_object
    obj.extend(role_module)
    obj.instance_variable_set(:@__brassbound_context, self)
    class << obj
      def context
        @__brassbound_context
      end
    end
    self.singleton_class.send(:define_method, role_name) do
      obj
    end
  end

  # Undo (most of) the effects of #apply_role. This method will remove all of
  # the methods that were added to the mapped data object by #apply role, but
  # the fact that the object has been extended with the role module cannot be
  # undone. Therefore, <tt>obj.kind_of?(role_module)</tt> will still be true,
  # even though the methods defined in role_module will have been removed from
  # the object.
  def unapply_role(role_name)
    role_mapping = self.roles[role_name]
    role_module, obj = role_mapping.role_module, role_mapping.data_object
    obj.instance_variable_set(:@__brassbound_context, nil)
    class << obj
      remove_method(:context)
    end
    role_module.instance_methods.each do |m|
      obj.singleton_class.send(:undef_method, m)
    end
    self.singleton_class.send(:undef_method, role_name)
  end

  def undef_role(role_module, obj)
    obj.instance_variable_set(:@__brassbound_context, nil)
    class << obj
      remove_method(:context)
    end
    role_module.instance_methods.each do |m|
      obj.singleton_class.send(:undef_method, m)
    end
  end

  # Begin execution of this context. Note that context implementations must
  # provide an #execute method, and should not override this #call method.
  # This method will first set Context.current to self, apply all of the
  # role mappings that have been declared with the #role method, and then
  # call the #execute method.
  #
  # After the #execute method has returned, it will unapply all role mappings
  # and set the current context back to its previous value.
  def call(*args)
    old_context = ::Brassbound::Context.current
    Thread.current[:brassbound_context] = self

    roles.each_key(&method(:apply_role))
    begin
      self.execute(*args)
    ensure
      roles.each_key(&method(:unapply_role))
      Thread.current[:brassbound_context] = old_context
    end
  end

private

  RoleMapping = Struct.new(:role_module, :data_object)
end

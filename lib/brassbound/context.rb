module Brassbound::Context
  def role(role_module, obj)
    obj.extend(role_module)
  end

  def undef_role(role_module, obj)
    role_module.instance_methods.each do |m|
      obj.singleton_class.send(:undef_method, m)
    end
  end

  def with_roles(role_map)
    role_map.each do |role_module, obj|
      self.role role_module, obj
    end

    yield

    role_map.each do |role_module, obj|
      self.undef_role(role_module, obj)
    end
  end

  def call(*args)
    self.execute(*args)
  end
end

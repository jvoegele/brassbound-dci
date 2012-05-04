require 'spec_helper'
include Brassbound

describe Context do
  include Context

  class Person
    attr_accessor :first_name, :last_name

    def initialize(first_name, last_name)
      @first_name = first_name
      @last_name = last_name
    end
  end

  module WifeRole
    def marry(husband)
      self.last_name = husband.last_name
    end
  end

  module HusbandRole
    def marry(wife)
    end
  end

  module MinisterRole
    def marry(husband, wife)
      "I, #{first_name} #{last_name}, now pronounce you Mr. and Mrs. #{wife.last_name}"
    end
  end

  let(:jason) { Person.new('Jason', 'Voegele') }
  let(:jennifer) { Person.new('Jennifer', 'Bollinger') }
  let(:mark) { Person.new('Mark', 'Schlafman') }

  context "#role" do
    it "should extend objects with role modules" do
      for person in [jason, jennifer, mark]
        person.should_not be_kind_of(HusbandRole)
        person.should_not be_kind_of(WifeRole)
        person.should_not be_kind_of(MinisterRole)
        person.should_not respond_to(:marry)
      end

      role HusbandRole, jason
      role WifeRole, jennifer
      role MinisterRole, mark

      jason.should be_kind_of(HusbandRole)
      jennifer.should be_kind_of(WifeRole)
      mark.should be_kind_of(MinisterRole)

      for person in [jason, jennifer, mark]
        person.should respond_to(:marry)
      end
    end
  end

  context "#undef_role" do
    it "should undefine methods but unfortunately cannot unextend the role module" do
      jason.should_not be_kind_of(HusbandRole)
      jason.should_not respond_to(:marry)

      role HusbandRole, jason
      jason.should be_kind_of(HusbandRole)
      jason.should respond_to(:marry)

      undef_role HusbandRole, jason
      jason.should_not respond_to(:marry)
      jason.should be_kind_of(HusbandRole)  # Not the desired situation, but limitation of Ruby
    end
  end

  context "#with_roles" do
    it "should associate objects with roles only for the scope of the given block" do
      for person in [jason, jennifer, mark]
        person.should_not be_kind_of(HusbandRole)
        person.should_not be_kind_of(WifeRole)
        person.should_not be_kind_of(MinisterRole)
        person.should_not respond_to(:marry)
      end

      with_roles(HusbandRole => jason, WifeRole => jennifer, MinisterRole => mark) do
        jason.should be_kind_of(HusbandRole)
        jennifer.should be_kind_of(WifeRole)
        mark.should be_kind_of(MinisterRole)

        for person in [jason, jennifer, mark]
          person.should respond_to(:marry)
        end
      end

      for person in [jason, jennifer, mark]
        person.should_not respond_to(:marry)
      end
      # The should be_kind_of assertions below are due to Ruby limitation.
      jason.should be_kind_of(HusbandRole)
      jennifer.should be_kind_of(WifeRole)
      mark.should be_kind_of(MinisterRole)
    end
  end

  it "should allow roles to inject behavior into objects" do
    with_roles(MinisterRole => mark, HusbandRole => jason, WifeRole => jennifer) do
      jennifer.marry(jason)
      jennifer.last_name.should == 'Voegele'
      mark.marry(jason, jennifer).should ==
        "I, Mark Schlafman, now pronounce you Mr. and Mrs. Voegele"
    end
  end
end

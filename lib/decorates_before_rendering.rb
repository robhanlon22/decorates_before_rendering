# -*- encoding : utf-8 -*-
require "decorates_before_rendering/version"
require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/class/attribute'
require 'active_support/concern'

# Decorates the specified fields. For instance, if you have
#
#   class StuffController < ApplicationController
#     include DecoratesBeforeRendering
#
#     decorates :thing_1, :thing_2
#   end
#
# @thing_1 and @thing_2 will be decorated right before a rendering occurs.
#
# You can also specify the decorator you wish to use for a particular instance variable:
#
#   class StuffController < ApplicationController
#     include DecoratesBeforeRendering
#
#     decorates :thing_1, :with => ThingListDecorator
#     decorates :thing_2
#   end
#
# @thing_1 will be a ThingListDecorator (or contain them), and @thing_2 will be a Thing2Decorator.
#
# For Draper 1.0 and above, collection elements are no longer decorated with
# Decorator.decorate(collection), but with Decorator.decorate_collection(collection).
# Specify that you want to decorate a collection, and with what decorator, with this syntax:
#
#   class StuffController < ApplicationController
#     include DecoratesBeforeRendering
#
#     decorates_collection :things_1, :with => ThingListDecorator
#   end
#
module DecoratesBeforeRendering
  extend ActiveSupport::Concern

  included do
    class_attribute :__decorates__, :instance_writer => false
    class_attribute :__decorates_collection__, :instance_writer => false

    class_eval do
      def self.decorates(*args)
        options = args.extract_options!

        self.__decorates__ ||= []
        self.__decorates__ << [ args.map { |i| "@#{i}" }, options ]
      end

      def self.decorates_collection(*args)
        options = args.extract_options!

        raise ArgumentError, ":with is required for now" if !options[:with]

        self.__decorates_collection__ ||= []
        self.__decorates_collection__ << [ args.map { |i| "@#{i}" }, options ]
      end
    end
  end

  def render(*args)
    __decorate_ivars__
    super(*args)
  end

private

  def __decorate_ivars__
    return if (__decorates__.nil? || __decorates__.empty?) and
              (__decorates_collection__.nil? || __decorates_collection__.empty?)

    if !__decorates__.nil?
      __decorate_ivar_names__(__decorates__) do |ivar_name, ivar, options|
        decorator = options.key?(:with) ? options.fetch(:with) : __decorator_for__(ivar)
        decorated = decorator.decorate(ivar)
        instance_variable_set(ivar_name, decorated)
      end
    end

    if !__decorates_collection__.nil?
      __decorate_ivar_names__(__decorates_collection__) do |ivar_name, ivar, options|
        decorated = options.fetch(:with).decorate_collection(ivar)
        instance_variable_set(ivar_name, decorated)
      end
    end
  end

  def __decorate_ivar_names__(ivars)
    ivars.each do |ivar_names, options|
      ivar_names.each do |ivar_name|
        ivar = instance_variable_get(ivar_name)
        if ivar
          yield ivar_name, ivar, options
        end
      end
    end
  end

  def __decorator_for__(ivar)
    __decorator_name_for__(ivar).constantize
  end

  def __decorator_name_for__(ivar)
    "#{__model_name_for__(ivar)}Decorator"
  end

  def __model_name_for__(ivar)
    if ivar.respond_to?(:model_name)
      source = ivar
    elsif ivar.class.respond_to?(:model_name)
      source = ivar.class
    else
      raise ArgumentError, "#{ivar} does not have an associated model"
    end

    source.model_name
  end
end

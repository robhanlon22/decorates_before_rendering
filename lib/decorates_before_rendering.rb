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
module DecoratesBeforeRendering
  extend ActiveSupport::Concern

  included do
    class_attribute :__decorates__, :instance_writer => false

    class_eval do
      def self.decorates(*args)
        options = args.extract_options!

        self.__decorates__ ||= []
        self.__decorates__ << [ args.map { |i| "@#{i}" }, options ]
      end
    end
  end

  def render(*args)
    __decorate_ivars__
    super(*args)
  end

private

  def __decorate_ivars__
    return if __decorates__.nil? || __decorates__.empty?

    __decorates__.each do |ivar_names, options|
      ivar_names.each do |ivar_name|
        ivar = instance_variable_get(ivar_name)
        if ivar
          decorator = options.key?(:with) ? options.fetch(:with) : __decorator_for__(ivar)
          decorated = decorator.decorate(ivar)
          instance_variable_set(ivar_name, decorated)
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

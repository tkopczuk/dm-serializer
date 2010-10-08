require 'dm-serializer/common'

require 'json'

module DataMapper
  module Serialize
    #
    # Converts the resource into a hash of properties.
    #
    # @param [Hash] options
    #   Additional options.
    #
    # @return [Hash{String => String}]
    #   The hash of resources properties.
    #
    # @since 1.0.1
    #
    def as_json(options = {})
      options = {} if options.nil?
      result  = {}

      properties_to_serialize(options).each do |property|
        property_name = property.name
        value = __send__(property_name)
        result[property_name] = value.kind_of?(DataMapper::Model) ? value.name : value
      end

      # add methods
      Array(options[:methods]).each do |method|
        next unless respond_to?(method)
        result[method] = __send__(method)
      end

      # Note: if you want to include a whole other model via relation, use :methods
      # comments.to_json(:relationships=>{:user=>{:include=>[:first_name],:methods=>[:age]}})
      # add relationships
      # TODO: This needs tests and also needs to be ported to #to_xml and #to_yaml
      (options[:relationships] || {}).each do |relationship_name, opts|
        next unless respond_to?(relationship_name)
        result[relationship_name] = __send__(relationship_name).to_json(opts.merge(:to_json => false))
      end

      result
    end

    # Serialize a Resource to JavaScript Object Notation (JSON; RFC 4627)
    #
    # @return <String> a JSON representation of the Resource
    def to_json(*args)
      options = args.first
      options = {} unless options.kind_of?(Hash)

      result = as_json(options)

      # default to making JSON
      if options.fetch(:to_json, true)
        result.to_json
      else
        result
      end
    end

    module ValidationErrors
      module ToJson
        def to_json(*args)
          errors.to_hash.to_json
        end
      end
    end

  end

  class Collection
    def to_json(*args)
      options = args.first
      options = {} unless options.kind_of?(Hash)

      resource_options = options.merge(:to_json => false)
      collection = map { |resource| resource.to_json(resource_options) }

      # default to making JSON
      if options.fetch(:to_json, true)
        collection.to_json
      else
        collection
      end
    end
    
    def as_json(*args)
      options = args.first
      options = {} unless options.kind_of?(Hash)

      resource_options = options.merge(:to_json => false)
      collection = map { |resource| resource.as_json(resource_options) }

      # default to making JSON
      if options.fetch(:to_json, true)
        collection.as_json
      else
        collection
      end
    end
  end

  if Serialize.dm_validations_loaded?

    module Validations
      class ValidationErrors
        include DataMapper::Serialize::ValidationErrors::ToJson
      end
    end

  end

end

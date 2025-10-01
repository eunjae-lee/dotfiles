require 'spec_helper'

RSpec.describe Dots::ConfigSchema do
  describe 'basic field validation' do
    it 'validates required string fields' do
      schema = described_class.new do
        required(:name).filled(:string)
      end

      errors = schema.validate({})
      expect(errors).to include("Missing or invalid 'name'")

      errors = schema.validate({ 'name' => 'John' })
      expect(errors).to be_empty
    end

    it 'validates optional fields' do
      schema = described_class.new do
        optional(:email).value(:string)
      end

      errors = schema.validate({})
      expect(errors).to be_empty

      errors = schema.validate({ 'email' => 'test@example.com' })
      expect(errors).to be_empty
    end

    it 'validates integer fields' do
      schema = described_class.new do
        required(:age).value(:integer)
      end

      errors = schema.validate({ 'age' => 25 })
      expect(errors).to be_empty

      errors = schema.validate({ 'age' => '30' })
      expect(errors).to be_empty

      errors = schema.validate({ 'age' => 'invalid' })
      expect(errors).to include("'age' must be a integer")
    end

    it 'validates boolean fields' do
      schema = described_class.new do
        optional(:active).value(:boolean)
      end

      errors = schema.validate({ 'active' => true })
      expect(errors).to be_empty

      errors = schema.validate({ 'active' => false })
      expect(errors).to be_empty

      errors = schema.validate({ 'active' => 'yes' })
      expect(errors).to include("'active' must be a boolean")
    end
  end

  describe 'array validation' do
    it 'validates arrays of strings' do
      schema = described_class.new do
        required(:tags).array(:string)
      end

      errors = schema.validate({ 'tags' => ['ruby', 'rails'] })
      expect(errors).to be_empty

      errors = schema.validate({ 'tags' => ['ruby', 123] })
      expect(errors).to include(match(/must be a string/))
    end

    it 'validates nested array schemas' do
      schema = described_class.new do
        required(:users).value(:array) do
          required(:name).filled(:string)
          required(:email).filled(:string)
        end
      end

      errors = schema.validate({
        'users' => [
          { 'name' => 'John', 'email' => 'john@example.com' }
        ]
      })
      expect(errors).to be_empty

      errors = schema.validate({
        'users' => [
          { 'name' => 'John' }
        ]
      })
      expect(errors).to include(match(/Missing or invalid 'email'/))
    end
  end

  describe 'unknown property detection' do
    it 'detects unknown properties' do
      schema = described_class.new do
        required(:name).filled(:string)
      end

      errors = schema.validate({ 'name' => 'John', 'age' => 25 })
      expect(errors).to include('Unknown properties: age')
    end

    it 'allows ignored keys' do
      schema = described_class.new do
        ignore :provider
        required(:name).filled(:string)
      end

      errors = schema.validate({ 'provider' => 'test', 'name' => 'John' })
      expect(errors).to be_empty
    end
  end

  describe 'at_least_one_of validator' do
    it 'validates that at least one field is present' do
      schema = described_class.new do
        optional(:packages).array(:string)
        optional(:casks).array(:string)
        at_least_one_of :packages, :casks
      end

      errors = schema.validate({})
      expect(errors).to include(match(/at least one of/))

      errors = schema.validate({ 'packages' => ['vim'] })
      expect(errors).to be_empty

      errors = schema.validate({ 'casks' => ['iterm2'] })
      expect(errors).to be_empty
    end
  end

  describe 'or type validation' do
    it 'validates or types' do
      or_type = Dots::ConfigSchema.or(:integer, :string)
      
      schema = described_class.new do
        required(:items).value(:array).each(or_type)
      end

      errors = schema.validate({ 'items' => [1, 'two', 3] })
      expect(errors).to be_empty

      errors = schema.validate({ 'items' => [1, { invalid: true }] })
      expect(errors).to include(match(/must be a integer or string/))
    end

    it 'validates or with schema' do
      hash_schema = described_class.new do
        required(:name).filled(:string)
      end

      or_type = Dots::ConfigSchema.or(:integer, hash_schema)
      
      schema = described_class.new do
        required(:items).value(:array).each(or_type)
      end

      errors = schema.validate({ 'items' => [1, { 'name' => 'test' }] })
      expect(errors).to be_empty

      errors = schema.validate({ 'items' => [{ 'invalid' => 'field' }] })
      expect(errors).to include(match(/Unknown properties/))
    end
  end
end

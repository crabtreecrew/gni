require 'spec_helper'

describe NameString do
  it 'should be able to parse uuid which are shorter than 32 hex characters' do
    name = 'Bubo bubo (Linnaeus )'
    uuid_hex = '00883aff-8a12-555b-9ce0-f8052d1dd4af'
    uuid = ::UUID.create_v5(name, Gni::Config.uuid_namespace)
    uuid_decimal = uuid.to_i
    uuid_decimal.to_s(16).size.should == 30
    uuid_decimal.should == 707348998430284602978567997448115375
    NameString.parse_uuid(uuid_decimal).should == uuid_hex
  end
end


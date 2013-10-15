ActiveRecord::Schema.define do
  create_table 'addresses' do |t|
    t.integer 'addressable_id'
    t.string 'addressable_type'
    t.string 'street'
    t.string 'city'
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table 'buildings' do |t|
    t.string 'name'
    t.integer 'owner_id'
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table 'cars' do |t|
    t.integer 'person_id'
    t.string 'brand'
    t.string 'model'
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table 'contacts' do |t|
    t.integer 'contactable_id'
    t.string 'contactable_type'
    t.string 'first_name'
    t.string 'last_name'
    t.date 'birthday'
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table 'floors' do |t|
    t.integer 'number'
    t.integer 'building_id'
    t.integer 'tenant_id'
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table 'people' do |t|
    t.string 'first_name'
    t.string 'last_name'
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end

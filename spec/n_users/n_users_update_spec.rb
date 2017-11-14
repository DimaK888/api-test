include Authorization

auth = AuthNewApi.new
users = Users.new

describe 'Изменение пользовательских данных POST(users/{user_id})' do
  before(:all) do
    email = Faker::Internet.email
    param = {
      email: email,
      password: 'qwer',
      profile_attributes: {
        name: Ryba::Name.full_name
      }
    }
    users.user_registration(param).request
    auth.auth(email, 'qwer')
    @user_id = Tokens.user_id
  end

  context 'когда владелец' do
    before(:all) do
      @param = {
        name: Ryba::Name.full_name,
        email: Faker::Internet.email,
        phone: random_mobile_phone,
        profile_attributes: {
          gender: [true, false].sample,
          birthday: Date.new(rand(1900..2100), rand(1..12), rand(1..28)).to_s,
          city_id: Region.new.city_by_ip[:city_id],
          about: Faker::Lorem.paragraph,
          contacts: users.expected_phone,
          position: Faker::StarWars.character,
          show_email: [true, false].sample,
          additional_contacts: Faker::Lorem.paragraph
        }
      }

      @changes = users.user_update(@param).request.parse_body['user']
    end

    it 'успешная смена name' do
      expect(@changes['profile']['name']).
        to eql(@param[:name])
    end

    it 'успешная смена email' do
      expect(@changes['email']).
        to eql(@param[:email])
    end

    it 'успешная смена phone' do
      expect(@changes['phone']).
        to eql(users.expected_phone(@param[:phone]))
    end

    it 'успешная смена city_id' do
      expect(@changes['profile']['city_id']).
        to eql(@param[:profile_attributes][:city_id])
    end

    it 'успешная смена contacts' do
      expect(@changes['profile']['contacts']).
        to eql(@param[:profile_attributes][:contacts])
    end

    it 'успешная смена gender' do
      expect(@changes['profile']['gender']).
        to eql(@param[:profile_attributes][:gender])
    end

    it 'успешная смена birthday' do
      expect(@changes['profile']['birthday']).
        to eql(@param[:profile_attributes][:birthday])
    end

    it 'успешная смена about' do
      expect(@changes['profile']['about']).
        to eql(@param[:profile_attributes][:about])
    end

    it 'успешная смена position' do
      expect(@changes['profile']['position']).
        to eql(@param[:profile_attributes][:position])
    end

    it 'успешная смена additional_contacts' do
      expect(@changes['profile']['additional_contacts']).
        to eql(@param[:profile_attributes][:additional_contacts])
    end

    it 'успешная смена show_email' do
      expect(@changes['profile']['show_email']).
        to eql(@param[:profile_attributes][:show_email])
    end
  end

  context 'когда сторонний пользователь' do
    before(:all) do
      auth.auth_as('user')
      param = { name: Ryba::Name.full_name }
      @changes = users.user_update(param, @user_id).request
    end

    it { expect(@changes).to response_code(403) }
  end

  context 'когда админ' do
    before(:all) do
      auth.auth_as('company')
      param = { name: Ryba::Name.full_name }
      @changes = users.user_update(param, @user_id).request
    end

    it { expect(@changes).to response_code(403) }
  end

  context 'когда неавторизован' do
    before(:all) do
      auth.log_out
      param = { name: Ryba::Name.full_name }
      @changes = users.user_update(param, @user_id).request(sign: false)
    end

    it { expect(@changes).to response_code(403) }
  end

  after(:all) { auth.log_out }
end

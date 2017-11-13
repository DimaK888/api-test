require 'spec_helper'

include Authorization

auth = AuthNewApi.new
users = Users.new

describe 'Авторизация в новом АПИ POST(/clients)' do
  shared_examples 'Авторизация с неверными данными' do |email, pswd|
    context 'Получим личные данные неавторизованного пользователя' do
      let(:user_info) { users.user_info(email: email).request }

      it "пользователя #{email} не существует (200)" do
        expect(user_info.code).to eq(200)
        expect(user_info.parse_body['users']).to be_empty
      end
    end

    context 'Авторизация' do
      it 'response 404' do
        expect(auth.auth(email, pswd).code).to eq(404)
      end
    end
  end

  shared_examples 'Авторизация с корректными данными' do |email, pswd|
    context "Авторизуемся под #{email}" do
      before(:all) do
        auth.log_out
        auth.auth(email, pswd)
      end

      it 'успешно!' do
        expect(Tokens.secret_token).not_to be_nil
      end

      it 'неавторизованный запрос users/{user_id} (403)' do
        expect(
          users.users(Tokens.user_id).request(sign: false).code
        ).to be(403)
      end

      it 'авторизованный запрос users/{user_id} (200)' do
        expect(
          users.users(Tokens.user_id).request.code
        ).to be(200)
      end

      context 'Обновим токен' do
        before(:all) do
          @old_secret_token = Tokens.secret_token
          auth.refresh_token
        end

        it 'secret_token сменился' do
          expect(@old_secret_token).not_to eql(Tokens.secret_token)
        end

        it 'авторизация сохранена' do
          expect(
            users.users(Tokens.user_id).request.code
          ).to be(200)
        end
      end
      after(:all) { auth.log_out }
    end
  end

  context 'под не существующим email' do
    include_examples 'Авторизация с неверными данными',
                     CREDENTIALS['not_exists']['email'],
                     CREDENTIALS['not_exists']['pswd']
  end

  context 'под удаленным пользователем' do
    include_examples 'Авторизация с неверными данными',
                     CREDENTIALS['deleted']['email'],
                     CREDENTIALS['deleted']['pswd']
  end

  context 'под не верным email' do
    include_examples 'Авторизация с неверными данными',
                     CREDENTIALS['incorrect']['email'],
                     CREDENTIALS['incorrect']['pswd']
  end

  context 'с пустым паролем' do
    include_examples 'Авторизация с неверными данными',
                     CREDENTIALS['not_exists']['email'],
                     ''
  end

  context 'с пустым email' do
    include_examples 'Авторизация с неверными данными',
                     '',
                     CREDENTIALS['company']['pswd']
  end

  context 'с пустыми полями' do
    include_examples 'Авторизация с неверными данными',
                     '',
                     ''
  end

  context 'как компания' do
    include_examples 'Авторизация с корректными данными',
                     CREDENTIALS['company']['email'],
                     CREDENTIALS['company']['pswd']
  end

  context 'как пользователь' do
    include_examples 'Авторизация с корректными данными',
                     CREDENTIALS['user']['email'],
                     CREDENTIALS['user']['pswd']
  end
end

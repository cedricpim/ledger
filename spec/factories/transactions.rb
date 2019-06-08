FactoryBot.define do
  factory :transaction, class: 'Ledger::Transaction' do
    account { 'Account' }
    date { Date.today.to_s }
    category { 'Category' }
    sequence(:description) { |s| "Description ##{s}" }
    venue { 'Venue' }
    amount { '+10.00' }
    currency { 'USD' }
    travel { '' }
  end
end

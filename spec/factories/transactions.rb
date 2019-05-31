FactoryBot.define do
  factory :transaction, class: 'Ledger::Transaction' do
    account { 'Account' }
    date { Date.today }
    category { 'Category' }
    sequence(:description) { |s| "Description ##{s}" }
    venue { 'Venue' }
    amount { '10.0' }
    currency { 'USD' }
    travel { nil }
  end
end

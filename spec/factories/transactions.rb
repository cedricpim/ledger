FactoryBot.define do
  factory :transaction, class: 'Ledger::Transaction' do
    account { 'Account' }
    date { Date.today.to_s }
    category { 'Category' }
    sequence(:description) { |seq| "Description ##{seq}" }
    venue { 'Venue' }
    amount { '+10.00' }
    currency { 'USD' }
    trip { '' }
  end

  after(:build) do |transaction, _evaluator|
    value = transaction.amount
    next if value.nil? || (value.is_a?(String) && value.start_with?(/-|\+/))

    value = value.to_s
    transaction.amount = value.start_with?('-') ? value : "+#{value}"
  end
end

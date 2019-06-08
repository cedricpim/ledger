FactoryBot.define do
  factory :networth, class: 'Ledger::Networth' do
    date { Date.today.to_s }
    invested { '+10.00' }
    investment { '+20.00' }
    amount { '+25.00' }
    currency { 'USD' }
  end
end

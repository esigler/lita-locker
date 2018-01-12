# frozen_string_literal: true

require 'spec_helper'

describe Locker::List do
  let(:item_class) { double('item class', list: [one, two, three, four]) }

  let(:one) { double('one') }
  let(:two) { double('two') }
  let(:three) { double('three') }
  let(:four) { double('four') }

  it 'raises an argument error if a non-integer page is requested' do
    expect { described_class.new(item_class, 3, 'z') }.to raise_error(ArgumentError)
  end

  describe '#multiple_pages' do
    it 'is true when there are more total items than can be displayed on one page' do
      subject = described_class.new(item_class, 1, 1)

      expect(subject).to be_multiple_pages
    end

    it 'is false when the whole list fits in one page' do
      subject = described_class.new(item_class, 10, 1)

      expect(subject).not_to be_multiple_pages
    end
  end

  describe '#requested_page' do
    context 'with an empty list' do
      let(:item_class) { double('item class', list: []) }

      it 'returns an empty list' do
        subject = described_class.new(item_class, 3, 1)

        expect(subject.requested_page).to be_empty
      end
    end

    context 'with a single item list' do
      let(:item_class) { double('item class', list: [one]) }

      it 'returns a list with one item' do
        subject = described_class.new(item_class, 3, 1)

        expect(subject.requested_page).to eq([one])
      end
    end

    context 'with a four item list' do
      it 'splits the pages correctly when there are two items per page' do
        subject = described_class.new(item_class, 2, 1)

        expect(subject.requested_page).to eq([one, two])

        subject = described_class.new(item_class, 2, 2)

        expect(subject.requested_page).to eq([three, four])
      end

      it 'splits the pages correctly when there are three items per page' do
        subject = described_class.new(item_class, 3, 1)

        expect(subject.requested_page).to eq([one, two, three])

        subject = described_class.new(item_class, 3, 2)

        expect(subject.requested_page).to eq([four])
      end
    end
  end

  describe '#valid_page?' do
    it 'is true when the first page is requested' do
      subject = described_class.new(item_class, 3, 1)

      expect(subject).to be_valid_page
    end

    it 'is true when the page is between 1 and the total number of pages' do
      subject = described_class.new(item_class, 3, 2)

      expect(subject).to be_valid_page
    end

    it 'is false when the page is less than 1' do
      subject = described_class.new(item_class, 3, 0)

      expect(subject).not_to be_valid_page
    end

    it 'is false when the page is greater than the total number of pages' do
      subject = described_class.new(item_class, 3, 10)

      expect(subject).not_to be_valid_page
    end
  end
end

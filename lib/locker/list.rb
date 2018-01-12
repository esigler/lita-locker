# frozen_string_literal: true

# Locker subsystem
module Locker
  # A paginated list of items (e.g. labels or resources).
  #
  # @api private
  class List
    # @return [#list] The Ruby class of the item to be listed.
    attr_reader :item_class

    # @return [Enumerable] The full list of items.
    attr_reader :list

    # @return [Integer] The number of items displayed per page.
    attr_reader :per_page

    # @return [Integer] The page the user has requested.
    attr_reader :page

    # @return [Integer] The total number of pages.
    attr_reader :pages

    # @return [Integer] The zero-based index offset that the requested page starts on within the full list.
    attr_reader :offset

    def initialize(item_class, per_page, page)
      @item_class = item_class
      @list = item_class.list
      @per_page = per_page
      @page = Integer(page.to_s, 10)
      @pages = (list.count / per_page).ceil + 1
      @offset = per_page * (self.page - 1)
    end

    # Whether or not the list has multiple pages.
    #
    # @return [Boolean]
    def multiple_pages?
      list.count > per_page
    end

    # An enumerable of the items in the requested page.
    #
    # @return [Enumerable]
    def requested_page
      list[offset, per_page]
    end

    # Whether or not the requested page exists.
    #
    # @return [Boolean]
    def valid_page?
      page >= 1 && page <= pages
    end
  end
end

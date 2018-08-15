module AmazonApi
  class Item
    def self.create(ecs_item)
      item = Item.new

      puts ecs_item

      ##### 商品情報
      # Amazonの商品コード
      item.asin = ecs_item.get('ASIN')
      # 商品ページのURL
      item.detail_page_url = ecs_item.get('DetailPageURL')
      # 小画像のURL
      item.small_image_url = ecs_item.get("SmallImage/URL")
      # 中画像のURL
      item.medium_image_url = ecs_item.get("MediumImage/URL")
      # 大画像のURL
      item.large_image_url = ecs_item.get("LargeImage/URL")

      ia =  ecs_item.get_element('ItemAttributes')
      ##### 商品属性
      # 著者
      item.author = ia.get("Author")
      # 作者
      item.creator = ia.get("Creator")
      # 出版日
      item.publication_date = ia.get("PublicationDate")
      # 出版社
      item.publisher = ia.get("Publisher")
      # タイトル
      item.title = ia.get("Title")
      # ページ数
      item.number_of_pages = ia.get("NumberOfPages")

      item
    end

    def initialize
      # @author = nil             # 著者(配列にしないといけない?)
      # @creator = nil            # 作者
      # @ean = nil                # EAN
      # @isbn = nil               # ISBN
      # # @list_price_amount は取得できない？ https://forums.aws.amazon.com/thread.jspa?messageID=767712&tstart=0
      # @publication_date = nil   # 出版日
      # @publisher = nil          # 出版社
      # @title = nil              # タイトル
      # @number_of_pages = nil    # ページ数
      # # レビュー関連
      # @average_rating = nil     #
    end
    # 商品情報
    attr_accessor :asin, :detail_page_url, :small_image_url, :medium_image_url, :large_image_url
    # 商品属性
    attr_accessor :author, :creator, :publication_date, :publisher, :title, :number_of_pages
    # レビュー関連
    attr_accessor :average_rating, :total_reviews, :total_review_pages

    def to_s
      "title=#{@title} author=#{@author}"
    end
  end
end
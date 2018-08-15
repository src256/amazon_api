require 'amazon/ecs'
require 'optparse'

module AmazonApi
  class RequestError < StandardError; end

  class Response
    def initialize(ecs_res, retry_count)
      @ecs_res = ecs_res
      @retry_count = retry_count
      @items = create_items
      @nodes = create_nodes
    end
    attr_reader :ecs_res, :retry_count
    attr_reader :items, :nodes

    private
    def create_items
      # 取得できる情報について
      # http://aidiary.hatenablog.com/entry/20100116/1263647145
      items = []
      @ecs_res.items.each do |ecs_item|
        item = Item.create(ecs_item)
        items << item
        # item_attributes = ecs_item.get_element('ItemAttributes')
        # item = Item.new
        # items << item
        # item.title = item_attributes.get('Title')
        # item.author = item_attributes.get('Author')
        #
        # # # タイトルを取得&表示
        # # puts item.get_element("Title").inner_text
        # # # 著者を取得&表示
        # # puts item.get_element("Author")
      end
      items
    end

    def create_nodes
      nodes = []
      @ecs_res.get_elements("BrowseNode").each do |ecs_node|
        node = Node.create(ecs_node)
        nodes << node
      end
      nodes
    end
  end

  class Core

    RETRY_COUNT = 3

    def self.run(argv)
      STDOUT.sync = true
      opts = {}
      opt = OptionParser.new(argv)
      opt.banner = "Usage: #{opt.program_name} [-h|--help] <args>"
      opt.version = VERSION
      opt.separator('')
      opt.separator("Options:")
      opt.on_head('-h', '--help', 'Show this message') do |v|
        puts opt.help
        exit
      end
      opt.on('-v', '--verbose', 'Verbose message') {|v| opts[:v] = v}
      opt.on('--dry-run', 'Message only') {|v| opts[:dry_run] = v}
      commands = ['search', 'lookup']
      opt.on('-c VAL', '--command=VAL', commands, commands.join("|")) {|v| opts[:c] = v }
      opt.parse!(argv)

      opts[:c] ||= 'search'

      Dotenv.load(File.expand_path('~/doc/app/keys/aws.env'))

      core = Core.new(ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_KEY'], ENV['ASSOCIATE_TAG'])

      if opts[:c] == 'search'
        res = core.search(argv[0])
        res.items.each do |item|
          pp item
        end
      elsif opts[:c] == 'lookup'
        res = core.lookup(argv[0])
        res.nodes.each do |node|
          pp node
        end
      else
        puts opt.help
        exit
      end

    end

    def initialize(aws_access_key_id, aws_secret_key, associate_tag)
      @aws_access_key_id = aws_access_key_id
      @aws_secret_key = aws_secret_key
      @associate_tag = associate_tag

      Amazon::Ecs.options = {
          :AWS_access_key_id => @aws_access_key_id,
          :AWS_secret_key => @aws_secret_key,
          :associate_tag => @associate_tag
      }
    end

    # search_index = 'KindleStore'
    def search(terms = '', opts = {})
      fill_search_opts(opts)
      item_search(terms, opts)
    end

    def lookup(browse_node_id, opts = {})
      fill_lookup_opts(opts)
      browse_node_lookup(browse_node_id, opts)
    end

    private
    def fill_search_opts(opts)
      opts[:search_index] ||= 'KindleStore'
      opts[:response_group] ||= 'Large'
      opts[:country] ||= 'jp'
    end

    def fill_lookup_opts(opts)
      opts[:country] ||= 'jp'
    end

    def item_search(terms, opts = {})
      retry_request { Amazon::Ecs.item_search(terms, opts) }
    end

    def browse_node_lookup(browse_node_id, opts)
      retry_request { Amazon::Ecs.browse_node_lookup(browse_node_id, opts) }
    end

    def retry_request(&block)
      # 一回のリクエストだと失敗することが多いので何回か実行する
      last_message = nil
      0.upto(RETRY_COUNT - 1) do |i|
        retry_count = (i + 1)
        begin
          ecs_res = block.call
          # リクエスト成功の場合ここで抜ける
          return Response.new(ecs_res, retry_count)
        rescue => e
#          STDERR.puts e.backtrace.join("\n")
          sleep_time = rand((i + 1) * 5)
          puts "retry! sleep #{sleep_time} sec."
          sleep(sleep_time)
          last_message = e.message
        end
      end
      msg = "#{RETRY_COUNT}回実行して失敗: #{last_message}"
      raise RequestError, msg
    end
  end
end
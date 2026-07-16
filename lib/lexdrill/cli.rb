# frozen_string_literal: true

class Lexdrill::CLI
  COMMANDS = {
    print_version: %w[version --version -v],
    print_help: %w[help --help -h],
    run_next: %w[next],
    run_hook: %w[hook],
    run_start: %w[start],
    run_stop: %w[stop],
    run_inspect: %w[inspect],
    run_beat: %w[beat],
    run_beat_alias: %w[polka waltz rock jazz jiga balkan samba],
    run_color: %w[color],
    run_add: %w[add],
    run_list: %w[list all],
    run_edit: %w[edit],
    run_stats: %w[stats],
    run_rand: %w[rand],
    run_go: %w[go],
    run_remote: %w[remote],
    run_oauth: %w[oauth],
    run_wb: %w[wb],
    run_sh: %w[sh ls],
    run_use: %w[use],
    run_open: %w[open],
    run_push: %w[push],
    run_pull: %w[pull]
  }.freeze

  def self.start(argv = ARGV)
    new(argv).start
  end

  def initialize(argv)
    @argv = argv
  end

  attr_reader :argv

  def start
    command = argv.first || "help"
    handler = COMMANDS.find { |_method, options| options.include?(command) }&.first
    return print_unknown_command(command) unless handler

    send(handler)
  end

  private

  def print_version
    puts Lexdrill::VERSION
    0
  end

  def print_help
    puts <<~HELP
      drill #{Lexdrill::VERSION} — vocabulary drilling in your terminal

      Usage:
        drill version   Print the gem version
        drill help      Show this help
        drill next      Print the current word and advance
        drill hook <zsh|bash>   Print the shell integration snippet
        drill start     Resume drilling (undoes stop)
        drill stop      Pause drilling everywhere until `start`
        drill inspect   Show the active config/counter/toggle state
        drill beat <2-8> [repetitions]   Set the rhythm (repetitions defaults to 8)
        drill beat none                 Disable the rhythm
        drill beat rand                 Ignore the counter/rhythm; show a random item each time
        drill polka|waltz|rock|jazz|jiga|balkan|samba [repetitions]
                        Shorthand for a fixed loop size (2 through 8, in order)
        drill color random|default   Color each word randomly, or by its show count (default)
        drill add <text>   Append a new item to the list (and push, if a sheet is selected)
        drill list         Show how many times each item has been shown (drill all also works)
        drill edit         Open the list file in $EDITOR/$VISUAL (falls back to vi)
        drill stats        Print items as <count>\t<phrase>, tab-separated, highest count first
        drill rand <n>     drill next shows a word ~1-in-n times (n=1 is every time)
        drill go <number>  Jump so the next `next` shows item <number> (1-based, see drill list)
        drill remote                Use a local service account key for Google Sheets auth
                                    (~/.drill/gcp-service-account.json) — no interactive sign-in
        drill oauth                  Use your personal Google login for Google Sheets auth
        drill wb                     Alias for drill wb index
        drill wb index               List known workbooks (name and URL)
        drill wb add <url>           Add a workbook by URL (named after its own title)
        drill wb remove <name>       Forget a workbook
        drill wb use <name>          Switch the active workbook
        drill sh                     Alias for drill sh index (drill ls also works)
        drill sh index               List the tabs in the active workbook
        drill sh add <name>          Create a new tab
        drill sh remove <name>       Delete a tab
        drill sh use <name>          Switch the active tab (pulls its contents)
        drill use <name>             Alias for drill sh use <name>
        drill open                   Open the active tab in your browser
        drill push                   Push the word list text to the active tab (overwrites it)
        drill pull                   Replace the local word list with the active tab's column A
    HELP
    0
  end

  def run_next
    return 0 if Lexdrill::Rand.skip?

    word = Lexdrill::WordList.next
    return print_next_failure unless word

    puts Lexdrill::LineFormatter.format(word)
    0
  end

  def print_next_failure
    return print_no_words(Lexdrill::WordList::PATH) if Lexdrill::WordList.words.empty?

    print_all_graduated
  end

  def print_all_graduated
    warn "drill: every item has reached #{Lexdrill::Stats::GRADUATION_THRESHOLD} shows — nothing left to drill"
    1
  end

  def print_no_words(path)
    warn "drill: no words found in #{path}"
    1
  end

  def run_hook
    shell = argv[1]
    return print_hook_usage unless shell

    print_hook_snippet(shell)
  end

  def print_hook_usage
    warn "usage: drill hook <zsh|bash>"
    1
  end

  def print_hook_snippet(shell)
    puts Lexdrill::ShellSnippet.for(shell)
    0
  rescue ArgumentError => error
    warn "drill: #{error.message}"
    1
  end

  def run_start
    Lexdrill::Toggle.start
    0
  end

  def run_stop
    Lexdrill::Toggle.stop
    0
  end

  def run_inspect
    puts Lexdrill::Inspector.report
    0
  end

  def run_beat
    arg = argv[1]
    return print_beat_usage unless arg
    return clear_beat if arg == "none"
    return set_rand_beat if arg == "rand"

    set_beat(arg.to_i, Lexdrill::Beat.repetitions_or_default(argv[2]))
  end

  def set_rand_beat
    Lexdrill::Beat.set_rand
    0
  end

  def run_beat_alias
    loop_size = Lexdrill::Beat::ALIASES.fetch(argv.first)
    set_beat(loop_size, Lexdrill::Beat.repetitions_or_default(argv[1]))
  end

  def set_beat(loop_size, repetitions)
    return print_invalid_loop_size unless Lexdrill::Beat.valid_loop_size?(loop_size)
    return print_invalid_repetitions unless repetitions.positive?

    Lexdrill::Beat.set(loop_size, repetitions)
    0
  end

  def clear_beat
    Lexdrill::Beat.clear
    0
  end

  def print_beat_usage
    warn "usage: drill beat <#{Lexdrill::Beat::MIN_LOOP_SIZE}-#{Lexdrill::Beat::MAX_LOOP_SIZE}> " \
         "<repetitions> | drill beat none | drill beat rand"
    1
  end

  def print_invalid_loop_size
    warn "drill: loop size must be between #{Lexdrill::Beat::MIN_LOOP_SIZE} and #{Lexdrill::Beat::MAX_LOOP_SIZE}"
    1
  end

  def print_invalid_repetitions
    warn "drill: repetitions must be a positive number"
    1
  end

  def run_color
    mode = argv[1]
    return print_color_usage unless mode
    return print_invalid_color(mode) unless Lexdrill::Color::VALID.include?(mode)

    Lexdrill::Color.set(mode)
    0
  end

  def print_color_usage
    warn "usage: drill color <#{Lexdrill::Color::VALID.join('|')}>"
    1
  end

  def print_invalid_color(mode)
    warn "drill: unknown color mode #{mode.inspect} (expected #{Lexdrill::Color::VALID.join(' or ')})"
    1
  end

  # Appends locally, then opportunistically pushes the updated list to the
  # active tab if one is selected — a failed push is reported but doesn't
  # change the exit code, since the local add always succeeds regardless.
  def run_add
    text = argv[1..].join(" ")
    return print_add_usage if text.empty?

    File.open(Lexdrill::WordList::PATH, "a", encoding: "UTF-8") { |file| file.puts(text) }
    puts "added: #{text}"
    push_after_add
    0
  end

  def push_after_add
    spreadsheet_id = Lexdrill::Workbooks.current_id
    sheet_name = Lexdrill::Workbooks.current_sheet
    return unless spreadsheet_id && sheet_name

    token = current_token
    return unless token

    Lexdrill::WordList.instance_variable_set(:@words, nil)
    perform_push(spreadsheet_id, sheet_name, token)
  rescue Lexdrill::GoogleAuth::AuthError, Lexdrill::ServiceAccountAuth::AuthError,
         Lexdrill::SheetsClient::ApiError, Lexdrill::HTTPClient::NetworkError => error
    warn "drill: added locally, but couldn't push to #{sheet_name.inspect}: #{error.message}"
  end

  def print_add_usage
    warn "usage: drill add <text>"
    1
  end

  def run_list
    words = Lexdrill::WordList.words
    return print_no_words(Lexdrill::WordList::PATH) if words.empty?

    counts = Lexdrill::Stats.counts
    words.each_with_index { |word, index| puts "#{index + 1}. #{word} (#{counts.fetch(word, 0)})" }
    0
  end

  def run_edit
    editor_cmd = (ENV["VISUAL"] || ENV["EDITOR"] || "vi").split
    system(*editor_cmd, Lexdrill::WordList::PATH) ? 0 : 1
  end

  def run_stats
    words = Lexdrill::WordList.words
    return print_no_words(Lexdrill::WordList::PATH) if words.empty?

    counts = Lexdrill::Stats.counts
    pairs = words.map { |word| [counts.fetch(word, 0), word] }.sort_by { |count, _word| -count }
    pairs.each { |count, word| puts "#{count}\t#{word}" }
    0
  end

  def run_rand
    denominator = argv[1].to_s.to_i
    return print_rand_usage unless denominator.positive?

    Lexdrill::Rand.set(denominator)
    0
  end

  def print_rand_usage
    warn "usage: drill rand <n>   (drill next shows a word ~1-in-n times; n=1 is every time)"
    1
  end

  def run_go
    words = Lexdrill::WordList.words
    return print_no_words(Lexdrill::WordList::PATH) if words.empty?

    total = words.size
    number = argv[1].to_s.to_i
    return print_go_usage(total) unless (1..total).cover?(number)

    target = words[number - 1]
    return print_go_graduated(target) if Lexdrill::Stats.graduated?(target)

    jump_to(target)
    0
  end

  def jump_to(target)
    active = Lexdrill::WordList.active_words
    step = Lexdrill::Beat.step_for_index(active.size, active.index(target))
    Lexdrill::Counter.new(Lexdrill::WordList::COUNTER_PATH).set(step)
  end

  def print_go_usage(total)
    warn "usage: drill go <number>   (1 through #{total}, see drill list)"
    1
  end

  def print_go_graduated(word)
    warn "drill: #{word.inspect} has already graduated and won't be selected by next"
    1
  end

  def run_remote
    Lexdrill::AuthMode.set(Lexdrill::AuthMode::REMOTE)
    puts "auth mode set: remote (service account)"
    0
  end

  def run_oauth
    Lexdrill::AuthMode.set(Lexdrill::AuthMode::OAUTH)
    puts "auth mode set: oauth (personal login)"
    0
  end

  def current_token
    case Lexdrill::AuthMode.current
    when Lexdrill::AuthMode::REMOTE then Lexdrill::ServiceAccountAuth.fetch_token!
    when Lexdrill::AuthMode::OAUTH then Lexdrill::GoogleAuth.ensure_token!
    end
  end

  def print_no_auth_mode
    warn "drill: no auth mode configured; run `drill remote` (service account) or `drill oauth` (personal login) first"
    1
  end

  def run_wb
    case argv[1]
    when nil, "index" then run_wb_index
    when "add" then run_wb_add
    when "remove" then run_wb_remove
    when "use" then run_wb_use
    else print_wb_usage
    end
  end

  def print_wb_usage
    warn "usage: drill wb index|add <url>|remove <name>|use <name>"
    1
  end

  def run_wb_index
    names = Lexdrill::Workbooks.names
    return print_no_workbooks if names.empty?

    current = Lexdrill::Workbooks.current_name
    names.each { |name| puts "#{current_marker(name == current)} #{name}  #{Lexdrill::Workbooks.url_for(name)}" }
    0
  end

  # A painted drill sign for the current item, or a blank space otherwise —
  # used by `drill wb`/`drill sh` to mark the active workbook/sheet.
  def current_marker(is_current)
    is_current ? Lexdrill::Colorizer.paint_yellow(Lexdrill::LineFormatter::SEPARATOR) : " "
  end

  def print_no_workbooks
    warn "drill: no workbooks configured; run `drill wb add <url>`"
    1
  end

  def run_wb_add
    url = argv[2]
    return print_wb_add_usage unless url

    spreadsheet_id = Lexdrill::Workbooks.extract_id(url)
    return print_invalid_wb_url(url) unless spreadsheet_id

    add_workbook(spreadsheet_id)
  rescue Lexdrill::GoogleAuth::AuthError, Lexdrill::ServiceAccountAuth::AuthError => error
    warn "drill: #{error.message}"
    1
  rescue Lexdrill::SheetsClient::ApiError => error
    print_sheets_api_error(error)
  rescue Lexdrill::HTTPClient::NetworkError => error
    warn "drill: network error talking to Google (#{error.message})"
    1
  end

  def add_workbook(spreadsheet_id)
    token = current_token
    return print_no_auth_mode unless token

    title = Lexdrill::SheetsClient.spreadsheet_title(spreadsheet_id, token)
    return print_wb_name_taken(title) if Lexdrill::Workbooks.names.include?(title)

    Lexdrill::Workbooks.add(title, spreadsheet_id)
    puts "workbook added: #{title.inspect}"
    0
  end

  def print_wb_add_usage
    warn "usage: drill wb add <url>"
    1
  end

  def print_invalid_wb_url(url)
    warn "drill: could not find a spreadsheet id in #{url.inspect}"
    1
  end

  def print_wb_name_taken(title)
    warn "drill: a workbook named #{title.inspect} is already configured"
    1
  end

  def run_wb_remove
    name = argv[2]
    return print_wb_remove_usage unless name
    return print_no_such_workbook(name) unless Lexdrill::Workbooks.remove(name)

    puts "workbook removed: #{name.inspect}"
    0
  end

  def print_wb_remove_usage
    warn "usage: drill wb remove <name>"
    1
  end

  def print_no_such_workbook(name)
    warn "drill: no workbook named #{name.inspect} (see `drill wb index`)"
    1
  end

  def run_wb_use
    name = argv[2]
    return print_wb_use_usage unless name
    return print_no_such_workbook(name) unless Lexdrill::Workbooks.use(name)

    puts "workbook set: #{name.inspect}"
    0
  end

  def print_wb_use_usage
    warn "usage: drill wb use <name>"
    1
  end

  def run_sh
    case argv[1]
    when nil, "index" then run_sh_index
    when "add" then run_sh_add
    when "remove" then run_sh_remove
    when "use" then run_sh_use
    else print_sh_usage
    end
  end

  def print_sh_usage
    warn "usage: drill sh index|add <name>|remove <name>|use <name>"
    1
  end

  def print_no_workbook_selected
    warn "drill: no workbook selected; run `drill wb add <url>` or `drill wb use <name>` first"
    1
  end

  def run_sh_index
    spreadsheet_id = Lexdrill::Workbooks.current_id
    return print_no_workbook_selected unless spreadsheet_id

    token = current_token
    return print_no_auth_mode unless token

    list_sheets(spreadsheet_id, token)
  rescue Lexdrill::GoogleAuth::AuthError, Lexdrill::ServiceAccountAuth::AuthError => error
    warn "drill: #{error.message}"
    1
  rescue Lexdrill::SheetsClient::ApiError => error
    print_sheets_api_error(error)
  rescue Lexdrill::HTTPClient::NetworkError => error
    warn "drill: network error talking to Google (#{error.message})"
    1
  end

  def list_sheets(spreadsheet_id, token)
    current = Lexdrill::Workbooks.current_sheet
    Lexdrill::SheetsClient.sheet_titles(spreadsheet_id, token).each do |title|
      puts "#{current_marker(title == current)} #{title}"
    end
    0
  end

  def run_sh_add
    name = argv[2]
    return print_sh_add_usage unless name

    spreadsheet_id = Lexdrill::Workbooks.current_id
    return print_no_workbook_selected unless spreadsheet_id

    token = current_token
    return print_no_auth_mode unless token

    add_sheet(spreadsheet_id, name, token)
  rescue Lexdrill::GoogleAuth::AuthError, Lexdrill::ServiceAccountAuth::AuthError => error
    warn "drill: #{error.message}"
    1
  rescue Lexdrill::SheetsClient::ApiError => error
    print_sheets_api_error(error, name)
  rescue Lexdrill::HTTPClient::NetworkError => error
    warn "drill: network error talking to Google (#{error.message})"
    1
  end

  def add_sheet(spreadsheet_id, name, token)
    sheet_id = Lexdrill::SheetsClient.add_sheet(spreadsheet_id, name, token)
    Lexdrill::Workbooks.set_current_sheet(name, sheet_id) unless Lexdrill::Workbooks.current_sheet
    puts "sheet added: #{name.inspect}"
    0
  end

  def print_sh_add_usage
    warn "usage: drill sh add <name>"
    1
  end

  def run_sh_remove
    name = argv[2]
    return print_sh_remove_usage unless name

    spreadsheet_id = Lexdrill::Workbooks.current_id
    return print_no_workbook_selected unless spreadsheet_id

    token = current_token
    return print_no_auth_mode unless token

    remove_sheet(spreadsheet_id, name, token)
  rescue Lexdrill::GoogleAuth::AuthError, Lexdrill::ServiceAccountAuth::AuthError => error
    warn "drill: #{error.message}"
    1
  rescue Lexdrill::SheetsClient::ApiError => error
    print_sheets_api_error(error, name)
  rescue Lexdrill::HTTPClient::NetworkError => error
    warn "drill: network error talking to Google (#{error.message})"
    1
  end

  def remove_sheet(spreadsheet_id, name, token)
    sheet_id = Lexdrill::SheetsClient.find_sheet_id(spreadsheet_id, name, token)
    return print_no_such_sheet(name) unless sheet_id

    Lexdrill::SheetsClient.delete_sheet(spreadsheet_id, sheet_id, token)
    puts "sheet removed: #{name.inspect}"
    0
  end

  def print_sh_remove_usage
    warn "usage: drill sh remove <name>"
    1
  end

  def print_no_such_sheet(name)
    warn "drill: no tab named #{name.inspect} in the current workbook"
    1
  end

  def run_sh_use
    use_sheet(argv[2])
  end

  # `drill use <name>` is a shortcut for `drill sh use <name>` — the name
  # sits at a different argv position, so this and run_sh_use share the
  # same underlying logic rather than duplicating it.
  def run_use
    use_sheet(argv[1])
  end

  def use_sheet(name)
    return print_sh_use_usage unless name

    spreadsheet_id = Lexdrill::Workbooks.current_id
    return print_no_workbook_selected unless spreadsheet_id

    token = current_token
    return print_no_auth_mode unless token

    select_sheet(spreadsheet_id, name, token)
  rescue Lexdrill::GoogleAuth::AuthError, Lexdrill::ServiceAccountAuth::AuthError => error
    warn "drill: #{error.message}"
    1
  rescue Lexdrill::SheetsClient::ApiError => error
    print_sheets_api_error(error, name)
  rescue Lexdrill::HTTPClient::NetworkError => error
    warn "drill: network error talking to Google (#{error.message})"
    1
  end

  def select_sheet(spreadsheet_id, name, token)
    sheet_id = Lexdrill::SheetsClient.find_sheet_id(spreadsheet_id, name, token)
    return print_no_such_sheet(name) unless sheet_id

    Lexdrill::Workbooks.set_current_sheet(name, sheet_id)
    perform_pull(spreadsheet_id, name, token)
  end

  def print_sh_use_usage
    warn "usage: drill sh use <name> (or drill use <name>)"
    1
  end

  def run_open
    url = Lexdrill::Workbooks.current_url
    return print_no_workbook_selected unless url

    sheet_id = Lexdrill::Workbooks.current_sheet_id
    Lexdrill::Browser.open(sheet_id ? "#{url}#gid=#{sheet_id}" : url)
    0
  end

  def print_no_sheet_selected
    warn "drill: no sheet selected; run `drill sh use <name>` first"
    1
  end

  def run_push
    spreadsheet_id = Lexdrill::Workbooks.current_id
    return print_no_workbook_selected unless spreadsheet_id

    sheet_name = Lexdrill::Workbooks.current_sheet
    return print_no_sheet_selected unless sheet_name

    token = current_token
    return print_no_auth_mode unless token

    perform_push(spreadsheet_id, sheet_name, token)
  rescue Lexdrill::GoogleAuth::AuthError, Lexdrill::ServiceAccountAuth::AuthError => error
    warn "drill: #{error.message}"
    1
  rescue Lexdrill::SheetsClient::ApiError => error
    print_sheets_api_error(error, sheet_name)
  rescue Lexdrill::HTTPClient::NetworkError => error
    warn "drill: network error talking to Google (#{error.message})"
    1
  end

  def perform_push(spreadsheet_id, sheet_name, token)
    rows = push_rows
    Lexdrill::SheetsClient.overwrite_sheet(spreadsheet_id, sheet_name, rows, token)
    puts "pushed #{rows.size} word(s) to #{sheet_name.inspect}"
    0
  end

  def push_rows
    Lexdrill::WordList.words.map { |word| [word] }
  end

  def run_pull
    spreadsheet_id = Lexdrill::Workbooks.current_id
    return print_no_workbook_selected unless spreadsheet_id

    sheet_name = Lexdrill::Workbooks.current_sheet
    return print_no_sheet_selected unless sheet_name

    token = current_token
    return print_no_auth_mode unless token

    perform_pull(spreadsheet_id, sheet_name, token)
  rescue Lexdrill::GoogleAuth::AuthError, Lexdrill::ServiceAccountAuth::AuthError => error
    warn "drill: #{error.message}"
    1
  rescue Lexdrill::SheetsClient::ApiError => error
    print_sheets_api_error(error, sheet_name)
  rescue Lexdrill::HTTPClient::NetworkError => error
    warn "drill: network error talking to Google (#{error.message})"
    1
  end

  def perform_pull(spreadsheet_id, sheet_name, token)
    words = Lexdrill::SheetsClient.read_column(spreadsheet_id, sheet_name, token)
    return print_empty_pull(sheet_name) if words.empty?

    File.write(Lexdrill::WordList::PATH, "#{words.join("\n")}\n", encoding: "UTF-8")
    puts "pulled #{words.size} word(s) from #{sheet_name.inspect}"
    0
  end

  def print_empty_pull(sheet_name)
    warn "drill: #{sheet_name.inspect} has no data to pull"
    1
  end

  def print_sheets_api_error(error, sheet_name = nil)
    status = error.status
    message = error.message
    case status
    when 404 then warn "drill: spreadsheet not found or not accessible (check `drill wb index`)"
    when 403 then warn "drill: access denied — make sure the spreadsheet is shared with the right account"
    when 400 then print_400_error(message, sheet_name)
    else warn "drill: Google Sheets API error (#{status}): #{message}"
    end
    1
  end

  def print_400_error(message, sheet_name)
    hint = " (is #{sheet_name.inspect} a real tab in the spreadsheet?)" if sheet_name
    warn "drill: #{message}#{hint}"
  end

  def print_unknown_command(command)
    warn "drill: unknown command #{command.inspect}"
    print_help
    1
  end
end

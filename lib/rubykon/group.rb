module Rubykon
  class Group

    attr_reader :liberty_count, :stones, :liberties

    def self.assign(stone, board)
      neighbours_by_color = color_to_neighbour(board, stone)
      join_group_of_friendly_stones(neighbours_by_color[stone.color], stone)
      create_own_group(stone) unless stone.group
      add_liberties(neighbours_by_color[Board::EMPTY_COLOR], stone)
      take_liberties_of_enemies(neighbours_by_color[stone.enemy_color], stone, board)
    end

    def initialize(stone)
      @liberties = {}
      @liberty_count = 0
      @stones = [stone]
      stone.join(self)
    end

    def connect(stone)
      return if stone.group == self
      if stone.group
        merge(stone.group)
      else
        add_stone(stone)
      end
      remove_connector_liberty(stone)
    end

    def add_liberty(field)
      return if already_counted_as_liberty?(field)
      @liberties[field.identifier] = field
      @liberty_count += 1
    end

    def remove_liberty(stone)
      return if already_counted_as_liberty?(stone)
      @liberties[stone.identifier] = stone
      @liberty_count -= 1
    end

    def caught?
      @liberty_count <= 0
    end

    def remove(board)
      @stones.each do |stone|
        empty_stone = Stone.new stone.x, stone.y, Board::EMPTY_COLOR
        board.set empty_stone
      end
      # we could track that from the start
      neighbouring_groups = liberties.values.map(&:group).compact.uniq
      neighbouring_groups.each do |group|
        group.gain_liberties_from_capture_of(self, board)
      end
      @stones
    end

    def gain_liberties_from_capture_of(group, board)
      new_liberties = liberties.values.select {|stone| stone.group == group}
      new_liberties.each do |stone|
        field = board[stone.x, stone.y]
        add_liberty(field)
      end
    end

    private
    def remove_connector_liberty(stone)
      liberties.delete(stone.identifier)
      @liberty_count -= 1
    end

    def add_stone(stone)
      stone.join(self)
      @stones << stone
    end

    def already_counted_as_liberty?(field)
      @liberties[field.identifier] == field
    end

    def merge(friendly_group)
      merge_stones(friendly_group)
      merge_liberties(friendly_group)
    end

    def merge_stones(friendly_group)
      friendly_group.stones.each { |stone| add_stone(stone) }
    end

    def merge_liberties(friendly_group)
      @liberty_count += friendly_group.liberty_count
      liberties.merge!(friendly_group.liberties) do |_key, my_field, other_field|
        if shared_liberty?(my_field, other_field)
          @liberty_count -= 1
        end
        my_field
      end
    end

    def shared_liberty?(my_field, other_field)
      my_field.color == Board::EMPTY_COLOR ||
        other_field.color == Board::EMPTY_COLOR
    end

    # TODO awful lot of class methods, there ought to be a better way
    def self.color_to_neighbour(board, stone)
      neighbours                  = board.neighbours_of(stone.x, stone.y)
      neighbours_by_color         = neighbours.group_by &:color
      neighbours_by_color.default = []
      neighbours_by_color
    end

    def self.take_liberties_of_enemies(enemy_neighbours, stone, board)
      enemy_neighbours.each do |enemy_stone|
        enemy_group = enemy_stone.group
        enemy_group.remove_liberty(stone)
        stone.group.liberties[enemy_stone.identifier] = enemy_stone
        stone.capture enemy_group.remove(board) if enemy_group.caught?
      end
    end

    def self.add_liberties(liberties, stone)
      liberties.each do |field|
        stone.group.add_liberty(field)
      end
    end

    def self.create_own_group(stone)
      stone.join(new(stone))
    end

    def self.join_group_of_friendly_stones(friendly_stones, stone)
      friendly_stones.each do |friendly_stone|
        friendly_stone.group.connect(stone)
      end
    end
  end
end
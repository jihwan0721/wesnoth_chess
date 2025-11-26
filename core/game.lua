-- [[ 1. 전역 변수 안전 선언 ]] --
local game = {}

game.selected_unit = nil
game.highlighted_hexes = {}

-- [[ 2. 게임 초기화 ]] --
function game.init()
    wesnoth.message("DEBUG", "Chess Game Init (Menu Action Mode)")

    -- (1) 유닛 배치
    local function spawn(side, type, x, y)
        wesnoth.put_unit({ x=x, y=y, type=type, side=side })
        local u = wesnoth.get_unit(x, y)
        if u then
            u.max_moves = 5; u.moves = 0; u.variables.chess_moved = false
        end
    end

    -- 백색 & 흑색 배치
    spawn(1, "Chess_Rook_White",   1, 10); spawn(1, "Chess_Knight_White", 2, 10)
    spawn(1, "Chess_Bishop_White", 3, 10); spawn(1, "Chess_Queen_White",  4, 10)
    spawn(1, "Chess_King_White",   5, 10); spawn(1, "Chess_Bishop_White", 6, 10)
    spawn(1, "Chess_Knight_White", 7, 10); spawn(1, "Chess_Rook_White",   8, 10)
    for x=1,8 do spawn(1, "Chess_Pawn_White", x, 9) end
    
    spawn(2, "Chess_Rook_Black",   1, 1);  spawn(2, "Chess_Knight_Black", 2, 1)
    spawn(2, "Chess_Bishop_Black", 3, 1);  spawn(2, "Chess_Queen_Black",  4, 1)
    spawn(2, "Chess_King_Black",   5, 1);  spawn(2, "Chess_Bishop_Black", 6, 1)
    spawn(2, "Chess_Knight_Black", 7, 1);  spawn(2, "Chess_Rook_Black",   8, 1)
    for x=1,8 do spawn(2, "Chess_Pawn_Black", x, 2) end

    -- (2) 유닛 개조 (무기/동맹 설정 불필요)
    local all_units = wesnoth.get_units({ side = "1,2" })
    for _, u in ipairs(all_units) do
        wesnoth.wml_actions.modify_unit({
            [1] = { "filter", { id = u.id } }, 
            max_moves = 5, moves = 0,
            ["movement_costs"] = { flat=1, castle=1, village=1, grassland=1, impassable=99 }
        })
    end

    -- (3) 좌클릭 이벤트: 유닛 선택
    wesnoth.wml_actions.event({
        name = "select",
        first_time_only = false,
        [1] = { "lua", { code = "if game then game.on_select() end" } }
    })

    -- (4) 우클릭 메뉴 등록 (핵심!)
    -- 땅을 우클릭했을 때 이동 가능한 곳이면 메뉴가 뜹니다.
    wesnoth.wml_actions.set_menu_item({
        id = "chess_move",
        description = "체스 이동/공격",
        image = "misc/hover-hex.png",
        allow_in_debug = false,
        show_if = "",
        needs_select = false,
        -- 메뉴가 뜨는 조건: 하이라이트 된 땅이어야 함
        [1] = { "show_if", {
            [1] = { "lua", { code = "return game.check_menu_condition()" } }
        }},
        
        -- 메뉴 클릭 시 실행할 행동
        [2] = { "command", {
            [1] = { "lua", { code = "game.execute_menu_action()" } }
        }}
    })

    -- (5) 턴 리프레시
    wesnoth.wml_actions.event({
        name = "turn refresh", first_time_only = false,
        [1] = { "lua", { code = [[
            local units = wesnoth.get_units({ side = wesnoth.current.side })
            for _, u in ipairs(units) do u.moves = 0 end
        ]] } }
    })
end

-- [[ 3. 유닛 선택 로직 (좌클릭) ]] --
function game.on_select()
    game.clear_highlights()
    game.clear_selected_unit_highlight()
    local x, y = wesnoth.interface.get_hovered_hex()
    local u = wesnoth.get_unit(x, y)
    -- 내 턴이고 내 유닛이면 선택
    if u and u.side == wesnoth.current.side then
        game.selected_unit = u
        game.selected_unit_hex = {x=u.x, y=u.y}
        wesnoth.wml_actions.item({ x=u.x, y=u.y, image="misc/hover-hex-yours-bottom.png" })
        game.highlight_moves(u) -- 이동 범위 표시
    else
        -- 빈 땅이나 적을 좌클릭하면 선택 해제
        game.selected_unit = nil
    end
end

-- [[ 4. 메뉴 조건 확인 (우클릭 시 발동) ]] --
function game.check_menu_condition()
    if not game.selected_unit then return false end
    
    local x, y = wesnoth.interface.get_hovered_hex()


    -- 지금 우클릭한 곳이 하이라이트 목록에 있는가?
    if game.highlighted_hexes then
        for _, hex in ipairs(game.highlighted_hexes) do
            if hex.x == x and hex.y == y then
                return true
            end
        end
    end
    return false
end

-- [[ 5. 메뉴 실행 로직 ]] --
function game.execute_menu_action()
    local x, y = wesnoth.interface.get_hovered_hex()

    
    -- 이동 정보 찾기
    local move_info = nil
    for _, hex in ipairs(game.highlighted_hexes) do
        if hex.x == x and hex.y == y then
            move_info = hex
            break
        end
    end

    if move_info then
        game.perform_move(x, y, move_info)
    end
end

-- [[ 6. 실제 이동 및 공격 (강제 집행) ]] --
function game.perform_move(to_x, to_y, move_info)
    local u = game.selected_unit
    if not u or not u.valid then return end
    
    local u_id = u.id
    local u_side = u.side
    local u_type = u.type
    local u_y = u.y

    -- 1. 하이라이트 제거
    game.clear_highlights()
    game.clear_selected_unit_highlight()
    
    -- 2. 도착지 확인 (적군 처리)
    local target = wesnoth.get_unit(to_x, to_y)
    if target then
        if target.side ~= u_side then
            -- 적군이면 삭제
            wesnoth.extract_unit(target)
            wesnoth.audio.play("sounds/mace.wav")
            wesnoth.message("CHESS", "적 제거 완료!")
        else
            return -- 아군이면 취소
        end
    end

    -- 3. 나 자신 이동 (put_unit)
    local me = wesnoth.get_unit(u_id)
    if me then wesnoth.extract_unit(me) end
    
    wesnoth.put_unit({ id=u_id, type=u_type, side=u_side, x=to_x, y=to_y, moves=0 })

    -- 4. 이동 기록 업데이트
    local moved_u = wesnoth.get_unit(to_x, to_y)
    if moved_u then moved_u.variables.chess_moved = true end

    -- 5. 캐슬링 처리
    if move_info.is_castle then
        if move_info.is_castle == "kingside" then
            local rook = wesnoth.get_unit(8, u_y)
            if rook then wesnoth.extract_unit(rook); wesnoth.put_unit({id=rook.id, type=rook.type, side=rook.side, x=6, y=u_y, moves=0}) end
        elseif move_info.is_castle == "queenside" then
            local rook = wesnoth.get_unit(1, u_y)
            if rook then wesnoth.extract_unit(rook); wesnoth.put_unit({id=rook.id, type=rook.type, side=rook.side, x=4, y=u_y, moves=0}) end
        end
    end

    -- 6. 턴 종료
    game.selected_unit = nil
    wesnoth.fire("end_turn")
    wesnoth.wml_actions.redraw({})
end

-- [[ 7. 하이라이트 표시 ]] --
function game.highlight_moves(u)
    local moves = game.get_legal_moves(u)
    for _, hex in ipairs(moves) do
        local target = wesnoth.get_unit(hex.x, hex.y)
        -- 적군은 빨강, 빈땅은 초록
        local img = "misc/hover-hex.png"
        
        wesnoth.wml_actions.item({ x=hex.x, y=hex.y, halo=img })
        table.insert(game.highlighted_hexes, { x=hex.x, y=hex.y, is_castle=hex.is_castle })
    end
    wesnoth.wml_actions.redraw({})
end

function game.clear_highlights()
    if not game.highlighted_hexes then return end
    for _, item in ipairs(game.highlighted_hexes) do
        wesnoth.wml_actions.remove_item({ x=item.x, y=item.y })
    end
    game.highlighted_hexes = {}
    wesnoth.wml_actions.redraw({})
end

function game.clear_selected_unit_highlight()
    if game.selected_unit_hex then
        wesnoth.wml_actions.remove_item({ x=game.selected_unit_hex.x, y=game.selected_unit_hex.y })
        game.selected_unit_hex = nil
    end
end
-- [[ 8. 이동 규칙 (Logic) ]] --
local function check_spot(u, x, y)
    if x < 1 or x > 8 or y < 1 or y > 10 then return "blocked" end
    local target = wesnoth.get_unit(x, y)
    if not target then return "empty"
    elseif target.side ~= u.side then return "enemy"
    else return "friend" end
end

function game.get_legal_moves(u)
    if u.type:find("Pawn") then return game.get_pawn_moves(u) end
    if u.type:find("Rook") then return game.get_rook_moves(u) end
    if u.type:find("Knight") then return game.get_knight_moves(u) end
    if u.type:find("Bishop") then return game.get_bishop_moves(u) end
    if u.type:find("Queen") then return game.get_queen_moves(u) end
    if u.type:find("King") then return game.get_king_moves(u) end
    return {}
end

function game.get_pawn_moves(u)
    local moves = {}
    local dy = (u.side == 1) and -1 or 1
    if check_spot(u, u.x, u.y+dy) == "empty" then
        table.insert(moves, {x=u.x, y=u.y+dy})
        if not u.variables.chess_moved then
            if check_spot(u, u.x, u.y+(dy*2)) == "empty" then
                table.insert(moves, {x=u.x, y=u.y+(dy*2)})
            end
        end
    end
    for _, dx in ipairs({-1, 1}) do
        if check_spot(u, u.x+dx, u.y+dy) == "enemy" then
            table.insert(moves, {x=u.x+dx, y=u.y+dy})
        end
    end
    return moves
end

local function get_sliding_moves(u, dirs)
    local moves = {}
    for _, dir in ipairs(dirs) do
        for i = 1, 8 do
            local nx, ny = u.x + (dir[1]*i), u.y + (dir[2]*i)
            local status = check_spot(u, nx, ny)
            if status == "empty" then table.insert(moves, {x=nx, y=ny})
            elseif status == "enemy" then table.insert(moves, {x=nx, y=ny}); break
            else break end
        end
    end
    return moves
end

local function get_step_moves(u, offsets)
    local moves = {}
    for _, off in ipairs(offsets) do
        local nx, ny = u.x + off[1], u.y + off[2]
        local status = check_spot(u, nx, ny)
        if status == "empty" or status == "enemy" then
            table.insert(moves, {x=nx, y=ny})
        end
    end
    return moves
end

function game.get_rook_moves(u) return get_sliding_moves(u, {{0,-1},{0,1},{-1,0},{1,0}}) end
function game.get_bishop_moves(u) return get_sliding_moves(u, {{-1,-1},{1,-1},{-1,1},{1,1}}) end
function game.get_queen_moves(u) return get_sliding_moves(u, {{0,-1},{0,1},{-1,0},{1,0},{-1,-1},{1,-1},{-1,1},{1,1}}) end
function game.get_knight_moves(u) return get_step_moves(u, {{1,-2},{2,-1},{2,1},{1,2},{-1,2},{-2,1},{-2,-1},{-1,-2}}) end
function game.get_king_moves(u)
    local moves = get_step_moves(u, {{0,-1},{0,1},{-1,0},{1,0},{-1,-1},{1,-1},{-1,1},{1,1}})
    if not u.variables.chess_moved then
        local y = u.y
        local rk = wesnoth.get_unit(8, y)
        if rk and not rk.variables.chess_moved and check_spot(u,6,y)=="empty" and check_spot(u,7,y)=="empty" then
            table.insert(moves, {x=7, y=y, is_castle="kingside"})
        end
        local rq = wesnoth.get_unit(1, y)
        if rq and not rq.variables.chess_moved and check_spot(u,2,y)=="empty" and check_spot(u,3,y)=="empty" and check_spot(u,4,y)=="empty" then
            table.insert(moves, {x=3, y=y, is_castle="queenside"})
        end
    end
    return moves
end

return game
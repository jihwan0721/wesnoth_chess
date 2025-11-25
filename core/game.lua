local game = {}

function game.init()
    wesnoth.message("DEBUG", "game.init() 실행됨")

    local w, h = wesnoth.get_map_size()
    wesnoth.message("DEBUG", "맵 크기 확인: " .. w .. " x " .. h)
    wesnoth.message("CHESS", "Spawning initial board pieces")

    -- White pieces
    wesnoth.put_unit({ x=1, y=10, type="Chess_Rook_White", side=1 })
    wesnoth.put_unit({ x=2, y=10, type="Chess_Knight_White", side=1 })
    wesnoth.put_unit({ x=3, y=10, type="Chess_Bishop_White", side=1 })
    wesnoth.put_unit({ x=4, y=10, type="Chess_Queen_White", side=1 })
    wesnoth.put_unit({ x=5, y=10, type="Chess_King_White", side=1 })
    wesnoth.put_unit({ x=6, y=10, type="Chess_Bishop_White", side=1 })
    wesnoth.put_unit({ x=7, y=10, type="Chess_Knight_White", side=1 })
    wesnoth.put_unit({ x=8, y=10, type="Chess_Rook_White", side=1 })

    for x = 1,8 do
        wesnoth.put_unit({ x=x, y=9, type="Chess_Pawn_White", side=1 })
    end

    -- Black pieces
    wesnoth.put_unit({ x=1, y=1, type="Chess_Rook_Black", side=2 })
    wesnoth.put_unit({ x=2, y=1, type="Chess_Knight_Black", side=2 })
    wesnoth.put_unit({ x=3, y=1, type="Chess_Bishop_Black", side=2 })
    wesnoth.put_unit({ x=4, y=1, type="Chess_Queen_Black", side=2 })
    wesnoth.put_unit({ x=5, y=1, type="Chess_King_Black", side=2 })
    wesnoth.put_unit({ x=6, y=1, type="Chess_Bishop_Black", side=2 })
    wesnoth.put_unit({ x=7, y=1, type="Chess_Knight_Black", side=2 })
    wesnoth.put_unit({ x=8, y=1, type="Chess_Rook_Black", side=2 })

    for x = 1,8 do
        wesnoth.put_unit({ x=x, y=2, type="Chess_Pawn_Black", side=2 })
    end
end
function game.on_select_unit()
    local u = wesnoth.get_unit(wesnoth.current.hex[0], wesnoth.current.hex[1])
    if not u then return end

    wesnoth.message("CHESS", "선택됨: "..u.type)

    game.selected = u

    -- 이동 가능 위치 표시
    game.highlight_moves(u)
end

function game.highlight_moves(u)
    wesnoth.wml_actions.scroll_to({x=u.x, y=u.y})
    
    -- 예시: 모든 방향 1칸 가능
    for dx = -1,1 do
        for dy = -1,1 do
            if not (dx==0 and dy==0) then
                local nx = u.x + dx
                local ny = u.y + dy
                
                wesnoth.wml_actions.item({
                    x=nx, 
                    y=ny,
                    image="misc/mark-hex.png"
                })
            end
        end
    end
end

function game.on_move_unit()
    if not game.selected then return end

    local u = game.selected
    local to_x = wesnoth.current.hex[0]
    local to_y = wesnoth.current.hex[1]

    wesnoth.message("CHESS", u.type.." 이동 → "..to_x..","..to_y)
    wesnoth.move_unit(u, to_x, to_y)

    game.selected = nil
end

return game
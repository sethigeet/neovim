local helpers = require('test.functional.helpers')(after_each)
local thelpers = require('test.functional.terminal.helpers')
local clear, eq, eval = helpers.clear, helpers.eq, helpers.eval
local feed, nvim = helpers.feed, helpers.nvim
local feed_data = thelpers.feed_data

describe(':terminal mouse', function()
  local screen

  before_each(function()
    clear()
    nvim('set_option', 'statusline', '==========')
    nvim('command', 'highlight StatusLine cterm=NONE')
    nvim('command', 'highlight StatusLineNC cterm=NONE')
    nvim('command', 'highlight VertSplit cterm=NONE')
    screen = thelpers.screen_setup()
    local lines = {}
    for i = 1, 30 do
      table.insert(lines, 'line'..tostring(i))
    end
    table.insert(lines, '')
    feed_data(lines)
    screen:expect([[
      line26                                            |
      line27                                            |
      line28                                            |
      line29                                            |
      line30                                            |
      {1: }                                                 |
      {3:-- TERMINAL --}                                    |
    ]])
  end)

  describe('when the terminal has focus', function()
    it('will exit focus on mouse-scroll', function()
      eq('t', eval('mode(1)'))
      feed('<ScrollWheelUp><0,0>')
      eq('nt', eval('mode(1)'))
    end)

    it('will exit focus on <C-\\> + mouse-scroll', function()
      eq('t', eval('mode(1)'))
      feed('<C-\\>')
      feed('<ScrollWheelUp><0,0>')
      eq('nt', eval('mode(1)'))
    end)

    it('does not leave terminal mode on left-release', function()
      if helpers.pending_win32(pending) then return end
      feed('<LeftRelease>')
      eq('t', eval('mode(1)'))
    end)

    describe('with mouse events enabled by the program', function()
      before_each(function()
        thelpers.enable_mouse()
        thelpers.feed_data('mouse enabled\n')
        screen:expect([[
          line27                                            |
          line28                                            |
          line29                                            |
          line30                                            |
          mouse enabled                                     |
          {1: }                                                 |
          {3:-- TERMINAL --}                                    |
        ]])
      end)

      it('will forward mouse clicks to the program', function()
        if helpers.pending_win32(pending) then return end
        feed('<LeftMouse><1,2>')
        screen:expect([[
          line27                                            |
          line28                                            |
          line29                                            |
          line30                                            |
          mouse enabled                                     |
           "#{1: }                                              |
          {3:-- TERMINAL --}                                    |
        ]])
      end)

      it('will forward mouse scroll to the program', function()
        if helpers.pending_win32(pending) then return end
        feed('<ScrollWheelUp><0,0>')
        screen:expect([[
          line27                                            |
          line28                                            |
          line29                                            |
          line30                                            |
          mouse enabled                                     |
          `!!{1: }                                              |
          {3:-- TERMINAL --}                                    |
        ]])
      end)

      it('will forward mouse clicks to the program with the correct even if set nu', function()
        if helpers.pending_win32(pending) then return end
        nvim('command', 'set number')
        -- When the display area such as a number is clicked, it returns to the
        -- normal mode.
        feed('<LeftMouse><3,0>')
        eq('nt', eval('mode(1)'))
        screen:expect([[
          {7: 11 }^line28                                        |
          {7: 12 }line29                                        |
          {7: 13 }line30                                        |
          {7: 14 }mouse enabled                                 |
          {7: 15 }rows: 6, cols: 46                             |
          {7: 16 }{2: }                                             |
                                                            |
        ]])
        -- If click on the coordinate (0,1) of the region of the terminal
        -- (i.e. the coordinate (4,1) of vim), 'CSI !"' is sent to the terminal.
        feed('i<LeftMouse><4,1>')
        screen:expect([[
          {7: 11 }line28                                        |
          {7: 12 }line29                                        |
          {7: 13 }line30                                        |
          {7: 14 }mouse enabled                                 |
          {7: 15 }rows: 6, cols: 46                             |
          {7: 16 } !"{1: }                                          |
          {3:-- TERMINAL --}                                    |
        ]])
      end)
    end)

    describe('with a split window and other buffer', function()
      if helpers.pending_win32(pending) then return end
      before_each(function()
        feed('<c-\\><c-n>:vsp<cr>')
        screen:expect([[
          line28                   │line28                  |
          line29                   │line29                  |
          line30                   │line30                  |
          rows: 5, cols: 25        │rows: 5, cols: 25       |
          {2:^ }                        │{2: }                       |
          ==========                ==========              |
          :vsp                                              |
        ]])
        feed(':enew | set number<cr>')
        screen:expect([[
          {7:  1 }^                     │line29                  |
          {4:~                        }│line30                  |
          {4:~                        }│rows: 5, cols: 25       |
          {4:~                        }│rows: 5, cols: 24       |
          {4:~                        }│{2: }                       |
          ==========                ==========              |
          :enew | set number                                |
        ]])
        feed('30iline\n<esc>')
        screen:expect([[
          {7: 27 }line                 │line29                  |
          {7: 28 }line                 │line30                  |
          {7: 29 }line                 │rows: 5, cols: 25       |
          {7: 30 }line                 │rows: 5, cols: 24       |
          {7: 31 }^                     │{2: }                       |
          ==========                ==========              |
                                                            |
        ]])
        feed('<c-w>li')
        screen:expect([[
          {7: 27 }line                 │line29                  |
          {7: 28 }line                 │line30                  |
          {7: 29 }line                 │rows: 5, cols: 25       |
          {7: 30 }line                 │rows: 5, cols: 24       |
          {7: 31 }                     │{1: }                       |
          ==========                ==========              |
          {3:-- TERMINAL --}                                    |
        ]])

        -- enabling mouse won't affect interaction with other windows
        thelpers.enable_mouse()
        thelpers.feed_data('mouse enabled\n')
        screen:expect([[
          {7: 27 }line                 │line30                  |
          {7: 28 }line                 │rows: 5, cols: 25       |
          {7: 29 }line                 │rows: 5, cols: 24       |
          {7: 30 }line                 │mouse enabled           |
          {7: 31 }                     │{1: }                       |
          ==========                ==========              |
          {3:-- TERMINAL --}                                    |
        ]])
      end)

      it('wont lose focus if another window is scrolled', function()
        feed('<ScrollWheelUp><4,0><ScrollWheelUp><4,0>')
        screen:expect([[
          {7: 21 }line                 │line30                  |
          {7: 22 }line                 │rows: 5, cols: 25       |
          {7: 23 }line                 │rows: 5, cols: 24       |
          {7: 24 }line                 │mouse enabled           |
          {7: 25 }line                 │{1: }                       |
          ==========                ==========              |
          {3:-- TERMINAL --}                                    |
        ]])
        feed('<S-ScrollWheelDown><4,0>')
        screen:expect([[
          {7: 26 }line                 │line30                  |
          {7: 27 }line                 │rows: 5, cols: 25       |
          {7: 28 }line                 │rows: 5, cols: 24       |
          {7: 29 }line                 │mouse enabled           |
          {7: 30 }line                 │{1: }                       |
          ==========                ==========              |
          {3:-- TERMINAL --}                                    |
        ]])
      end)

      it('will lose focus if another window is clicked', function()
        feed('<LeftMouse><5,1>')
        screen:expect([[
          {7: 27 }line                 │line30                  |
          {7: 28 }l^ine                 │rows: 5, cols: 25       |
          {7: 29 }line                 │rows: 5, cols: 24       |
          {7: 30 }line                 │mouse enabled           |
          {7: 31 }                     │{2: }                       |
          ==========                ==========              |
                                                            |
        ]])
      end)

      it('handles terminal size when switching buffers', function()
        nvim('set_option', 'hidden', true)
        feed('<c-\\><c-n><c-w><c-w>')
        screen:expect([[
          {7: 27 }line                 │line30                  |
          {7: 28 }line                 │rows: 5, cols: 25       |
          {7: 29 }line                 │rows: 5, cols: 24       |
          {7: 30 }line                 │mouse enabled           |
          {7: 31 }^                     │{2: }                       |
          ==========                ==========              |
                                                            |
        ]])
        feed(':bn<cr>')
        screen:expect([[
          rows: 5, cols: 25        │rows: 5, cols: 25       |
          rows: 5, cols: 24        │rows: 5, cols: 24       |
          mouse enabled            │mouse enabled           |
          rows: 5, cols: 25        │rows: 5, cols: 25       |
          {2:^ }                        │{2: }                       |
          ==========                ==========              |
          :bn                                               |
        ]])
        feed(':bn<cr>')
        screen:expect([[
          {7: 27 }line                 │rows: 5, cols: 24       |
          {7: 28 }line                 │mouse enabled           |
          {7: 29 }line                 │rows: 5, cols: 25       |
          {7: 30 }line                 │rows: 5, cols: 24       |
          {7: 31 }^                     │{2: }                       |
          ==========                ==========              |
          :bn                                               |
        ]])
      end)
    end)
  end)
end)

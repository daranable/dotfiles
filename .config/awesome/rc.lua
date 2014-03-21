-------------------------------------------------------------------------------
-- Initialize                                                                --
-------------------------------------------------------------------------------

-- Require Standard 'awesome' Libraries.
local gears      = require( "gears" );
local awful      = require( "awful" );
awful.autofocus  = require( "awful.autofocus" );
awful.rules      = require( "awful.rules" );
local awesome    = require( "awesome" );

-- Widget and layout library
local wibox      = require( "wibox" );

-- Theme Handling
local beautiful  = require( "beautiful" );

-- Notification Library
local naughty    = require( "naughty" );

-- Menu bar
local menubar    = require( "menubar" );

-- Define global variables *shutters*
local config_dir = awful.util.getdir( "config" );
local theme_file = config_dir .. "/themes/awesome-solarized/dark/theme.lua";

local browser    = "firefox";
local mail       = "thunderbird";
local terminal   = "xterm";
local editor     = os.getenv( "EDITOR" ) or "vim";
local editor_cmd = terminal .. " -e " .. editor;

-- Set the modkey for awesome
local modkey = "Mod1";

-- Define we do not want title bars.
use_titlebar = false;

-- Defaults
local mwfact = 0.5;
local default_layout = awful.layout.suit.tile;

-- Initialize the theme
beautiful.init( theme_file );

-------------------------------------------------------------------------------
-- Error Handling                                                            --
-------------------------------------------------------------------------------

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = err })
        in_error = false
    end)
end
-- }}}

-------------------------------------------------------------------------------
-- Bug Fix                                                                   --
-------------------------------------------------------------------------------

local setscreen = awful.tag.setscreen;

awful.tag.setscreen = function( tag, target_screen )
    if not tag or type(tag) ~= "tag" then return end
    setscreen( tag, target_screen );
    
    for _, client in ipairs( tag:clients() ) do
        -- Move all client's screen's
        client.screen = target_screen or 1;
        -- Fix some strange side effects
        client:tags( {tag} );
    end
end

-------------------------------------------------------------------------------
-- Tag Creation                                                              --
-------------------------------------------------------------------------------

-- In order to handle proper tag swapping in Awesome.
-- All tags are created on screen 1, if there is more than one screen,
-- Move one tag to each screen.  When a tag is switched, detect the screen
-- that the mouse is focussed on, Check the screen the tag is on,
-- swap screens of the two tags.

local tags = { };
-- How many default tags we want. {Default 10}
local tag_count = 10;

tags = { unpack( 
    awful.tag( 
        { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 }, 
        1, 
        awful.layout.suit.tile 
    )
) };

for s=1, screen.count() do
    -- On start, set one of the first tags to each screen.
    awful.tag.setscreen( tags[ s ], s );
    awful.tag.viewonly( tags[ s ] );
end

-------------------------------------------------------------------------------
-- Mouse Bindings                                                            --
-------------------------------------------------------------------------------

root.buttons( awful.util.table.join( 
    -- Right click = Open context menu
    awful.button( { }, 3, function () mymainmenu:toggle() end )
));

local clientbuttons = awful.util.table.join(
    awful.button( { }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize)
);

-------------------------------------------------------------------------------
-- Global Bindings                                                           --
-------------------------------------------------------------------------------

local globalkeys = awful.util.table.join( 
    -- Controlling the Awesome
    awful.key( { modkey,            }, "q", awesome.restart ),
    awful.key( { modkey, "Shift"    }, "q", awesome.quit    ),

    -- Focus selection
    awful.key( { modkey,            }, "j", function ()
        awful.client.focus.byidx( 1 );
        if client.focus then
            client.focus:raise();
        end
    end ),
    awful.key( { modkey,            }, "j", function ()
        awful.client.focus.byidx( -1 );
        if client.focus then
            client.focus:raise();
        end
    end ),
    awful.key( { modkey,            }, "Tab", function ()
        awful.client.focus.history.previous();
        if client.focus then
            client.focus:raise();
        end
    end ),

    
    -- Focus urgent window
    awful.key( { modkey,            }, "u", awful.client.urgent.jumpto),
    
    -- Change mwfact
    awful.key( { modkey,            }, "l", function () 
        awful.tag.incmwfact( 0.05 );
    end ),
    awful.key( { modkey,            }, "h", function () 
        awful.tag.incmwfact( -0.05 );
    end ),
    
    -- Change number of master windows
    awful.key( { modkey,            }, ",", function () 
        awful.tag.incnmaster( 1 );
    end ),
    awful.key( { modkey,            }, ".", function () 
        awful.tag.incnmaster( -1 )
    end ),
    
    -- Cycle through layouts
    awful.key( { modkey,            }, "space", function () 
        awful.layout.inc(layouts,  1) 
    end ),
    
    -- Reset to default layout
    awful.key( { modkey, "Shift"    }, "space", function ()
        awful.layout.set( default_layout );
    end ),
    
    -- Run prompt dialog
    awful.key( { modkey, "Shift"    }, "p", function ()
        awful.util.spawn( 'gmrun' );
    end ),
    
    -- Execute lua in context of WM.
    awful.key( { modkey,            }, "x", function ()
        awful.prompt.run(
                { prompt = "Run Lua code: " },
                mypromptbox[mouse.screen].widget,
                awful.util.eval, nil,
                awful.util.getdir("cache") .. "/history_eval"
        );
    end ),
    
    -- Focus Master window
    awful.key( { modkey,            }, "m", function ()
        client.focus = awful.client.getmaster();
    end ),

    awful.key( { modkey, "Shift"    }, "Return", function()
        awful.util.spawn( terminal );
    end )
);

-------------------------------------------------------------------------------
-- Client Bindings                                                           --
-------------------------------------------------------------------------------

local clientkeys = awful.util.table.join(
    -- Toggle full screen
    awful.key( { modkey,            }, "f", function ( c )
        c.fullscreen = not c.fullscreen;
    end ),
    
    -- Kill client
    awful.key( { modkey, "Shift"     }, "c", function ( c )
        c:kill();
    end ),
    
    -- Toggle floating of client
    awful.key( { modkey, "Control"   }, "space", awful.client.floating.toggle ),
    
    -- Swap client with master
    awful.key( { modkey,             }, "Return", function (c) 
        c:swap( awful.client.getmaster( mouse.screen ) );
    end ),

    -- Move client to other screen
    awful.key( { modkey,             }, "o", awful.client.movetoscreen ),
    
    -- Toggle if ontop
    awful.key( { modkey,             }, "t", function (c) 
        c.ontop = not c.ontop;
    end )
);

-------------------------------------------------------------------------------
-- Tag Control                                                               --
-------------------------------------------------------------------------------

function tag_is_visible( tag )
    for s = 1, screen.count() do
        if awful.tag.selected( s ) == tag then return true; end
    end
end

for index = 1, tag_count do
    local key;
    -- If this is index 10 bind the key to 0
    if index == 10 then 
        key = 0;
    else
        key = index
    end
    globalkeys = awful.util.table.join( globalkeys,
        awful.key( { modkey }, key, function ()
            -- Swap tags
            local curscreen = mouse.screen;
            local curtag = awful.tag.selected( curscreen );
            local tag = tags[ index ];
            
            if curtag == tag then return end
            
            --awful.tag.viewnone( curscreen );

            if tag_is_visible( tag ) then
                local oldscreen = awful.tag.getscreen( tag );

                awful.tag.setscreen( curtag, oldscreen );
                awful.tag.setscreen( tag, curscreen );
            else
                awful.tag.setscreen( tag, curscreen );
            end

            awful.tag.viewonly( tag );
        end ),
        awful.key( { modkey, "Shift" }, key, function ()
            local tag = tags[ index ];
            if client.focus and tag then
                awful.client.movetotag( tag );
            end
        end )
    );
end

root.keys( globalkeys );

-------------------------------------------------------------------------------
-- Awful Rules                                                               --
-------------------------------------------------------------------------------

awful.rules.rules = {
    -- All Clients will match this rule.
    { 
        rule = { },
        properties = {
            border_width = beautiful.border_width,
            border_color = beautiful.border_normal,
            focus = awful.client.focus.filter,
            keys = clientkeys,
            buttons = clientbuttons 
        } 
    },
    {
        rule = { class = "MPlayer" },
        properties = { floating = true }
    },
    {
        rule = { class = "feh" },
        properties = { floating = true }
    },
    {
        rule = { class = "gimp" },
        properties = { floating = true }
    },
    {
        rule = { instance = "plugin-container" },
        properties = { floating = true }
    },
}

-------------------------------------------------------------------------------
-- Load Everything                                                           --
-------------------------------------------------------------------------------

client.connect_signal( "manage", function( c, startup )
    -- Focus follows mouse
    c:connect_signal( "mouse::enter", function(c)
        if awful.layout.get( c.screen ) ~= awful.layout.suit.magnifier
                and awful.client.focus.filter( c ) then
            client.focus = c
        end
    end );

    if not startup then
        -- Set the windows at the slave,
        -- i.e. put it at the end of others instead of setting it master.
        -- awful.client.setslave(c)

        -- Put windows in a smart way, only if they does not set an 
        -- initial position.
        if not c.size_hints.user_position 
                and not c.size_hints.program_position then
            awful.placement.no_overlap( c );
            awful.placement.no_offscreen( c );
        end
    end
end );

-- Set focus borders
client.connect_signal( "focus", function( c )
    c.border_color = beautiful.border_focus;
end );
client.connect_signal( "unfocus", function( c )
    c.border_color = beautiful.border_normal;
end );

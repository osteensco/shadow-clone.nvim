local cmds = require('shadow-clone.commands')

describe("commands.lua", function()
    -- Initialize commands to ensure they are registered
    before_each(function()
        cmds.init()
    end)

    it("should register SCwindow", function()
        -- Ensure SCwindow command exists
        local result = vim.cmd['SCwindow']
        assert.is_true(result ~= nil)
    end)

    it("should register SCbubbleup", function()
        -- Ensure SCbubbleup command exists
        local result = vim.cmd['SCbubbleup']
        assert.is_true(result ~= nil)
    end)

    it("should register SCbubbledown", function()
        -- Ensure SCbubbledown command exists
        local result = vim.cmd['SCbubbledown']
        assert.is_true(result ~= nil)
    end)

    it("should register SCbubbledownh", function()
        -- Ensure SCbubbledownh command exists
        local result = vim.cmd['SCbubbledownh']
        assert.is_true(result ~= nil)
    end)

    it("should register SCbubbledownv", function()
        -- Ensure SCbubbledownv command exists
        local result = vim.cmd['SCbubbledownv']
        assert.is_true(result ~= nil)
    end)

    it("should register SCmoveleft", function()
        -- Ensure SCmoveleft command exists
        local result = vim.cmd['SCmoveleft']
        assert.is_true(result ~= nil)
    end)

    it("should register SCmoveright", function()
        -- Ensure SCmoveright command exists
        local result = vim.cmd['SCmoveright']
        assert.is_true(result ~= nil)
    end)

    it("should register SCmoveup", function()
        -- Ensure SCmoveup command exists
        local result = vim.cmd['SCmoveup']
        assert.is_true(result ~= nil)
    end)

    it("should register SCmovedown", function()
        -- Ensure SCmovedown command exists
        local result = vim.cmd['SCmovedown']
        assert.is_true(result ~= nil)
    end)

    it("should register SCsplit", function()
        -- Ensure SCsplit command exists
        local result = vim.cmd['SCsplit']
        assert.is_true(result ~= nil)
    end)

    it("should register SCvsplit", function()
        -- Ensure SCvsplit command exists
        local result = vim.cmd['SCvsplit']
        assert.is_true(result ~= nil)
    end)
end)

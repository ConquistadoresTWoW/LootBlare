config = {
  FRAME_WIDTH = 185,
  FRAME_HEIGHT = 300,
  BUTTON_WIDTH = 32,
  BUTTON_COUNT = 3,
  BUTTON_PADING = 10,
  CLICKABLE_TEXT_HEIGHT = 14,
  CLICKABLE_TEXT_FONT_SIZE = 11,
  FONT_NAME = 'Interface\\AddOns\\LootBlare\\assets\\BalooBhaina.ttf',
  FONT_SIZE = 16,
  FONT_OUTLINE = 'THICKOUTLINE',
  RAID_CLASS_COLORS = {
    ['Warrior'] = 'FFC79C6E',
    ['Mage'] = 'FF69CCF0',
    ['Rogue'] = 'FFFFF569',
    ['Druid'] = 'FFFF7D0A',
    ['Hunter'] = 'FFABD473',
    ['Shaman'] = 'FF0070DE',
    ['Priest'] = 'FFFFFFFF',
    ['Warlock'] = 'FF9482C9',
    ['Paladin'] = 'FFF58CBA',
    ['unknown'] = 'FFAD0202'
  },
  CHAT_COLORS = {
    POSITIVE = 'FF00FF00', -- Green
    NEGATIVE = 'FFFF0000', -- Red
    NEUTRAL = 'FFFFFF00', -- Yellow
    INFO = 'FF69CCF0', -- Light blue
    WARNING = 'FFFFA500', -- Orange
    HIGHLIGHT = 'FFFFFFFF' -- White
  },
  ADDON_TEXT_COLOR = 'FFEDD8BB',
  DEFAULT_TEXT_COLOR = 'FFFFFF00',
  ADDON_TEXT_COLOR_RGB = {0.93, 0.85, 0.73},
  SR_MS_TEXT_COLOR = 'FFFF0000',
  MS_TEXT_COLOR = 'FFFF7300',
  SR_OS_TEXT_COLOR = 'FFFFFF00',
  OS_TEXT_COLOR = 'FF00FF00',
  TM_TEXT_COLOR = 'FF00FFFF',
  LB_PREFIX = 'LootBlare',
  LB_GET_ML_SETTINGS = 'Get MLS',
  LB_SET_ML_SETTINGS = 'Set MLS:',
  LB_SET_PRIO_MAINS_FALSE = 'mp f',
  LB_SET_PRIO_MAINS_TRUE = 'mp t',
  LB_CLEAR_SR = 'clear sr',
  LB_ADD_SR = 'add sr:',
  LB_START_ROLL = 'start roll',
  LB_STOP_ROLL = 'stop roll',
  LB_ADD_ALTS = 'add alts:',
  LB_CLEAR_ALTS = 'clear alts',
  LB_ADD_PLUS_ONE = 'add plus:',
  LB_CLEAR_PLUS_ONE = 'clear plus',
  GRESSIL = 'Gressil, Dawn of Ruin',
  GH_LINK = "https://github.com/ConquistadoresTWoW/LootBlare/",
  

  MIN_FRAME_WIDTH = 150,
  MIN_FRAME_HEIGHT = 200,
  RESIZE_HANDLE_SIZE = 16,
  ITEM_QUALITY_COLORS = {
    [0] = {hex = "ff9d9d9d", r = 0.62, g = 0.62, b = 0.62}, -- Poor
    [1] = {hex = "ffffffff", r = 1.00, g = 1.00, b = 1.00}, -- Common
    [2] = {hex = "ff1eff00", r = 0.12, g = 1.00, b = 0.00}, -- Uncommon
    [3] = {hex = "ff0070dd", r = 0.00, g = 0.44, b = 0.87}, -- Rare
    [4] = {hex = "ffa335ee", r = 0.64, g = 0.21, b = 0.93}, -- Epic
    [5] = {hex = "ffff8000", r = 1.00, g = 0.50, b = 0.00}  -- Legendary
  },
  FONT_COLOR_CODE_CLOSE = "|r"
}
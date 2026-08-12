-- Core/Locale.lua
-- Ultra-light localization (only user-facing chat strings).
local _, TP = ...

TP.L = TP.L or {}

local LOCALES = {
    enUS = {
        GOLD = "Gold",
        ON = "ON",
        OFF = "OFF",
        CMD_HELP = "Commands: /tp status | debug on|off | log",
        STATUS_FMT = "status: debug=%s",
        DEBUG_ON = "debug ON",
        DEBUG_OFF = "debug OFF",
        UNKNOWN_CMD = "Unknown command. /tp help",
        SETTINGS_CATEGORY = "TrashPanda",
        FAST_LOOT_LABEL = "Faster Looting",
        LANGUAGE_LABEL = "Language",
        HUMOR_POS = {
            "Need more gold!",
            "You can build a ziggurat!",
            "Rich like a goblin beach",
            "Time is money, friend",
            "Greed is good",
            "Gold again?",
            "Won't the pockets burst?",
            "It rings too quietly",
            "Guys, his pockets are shining!",
            "Trash done",
            "More coin, less junk",
            "Goblin-grade profits",
        
        },
        HUMOR_NEG = {
            "Someone's been getting smacked",
            "Stop face-tanking",
            "Someone's been eating cleaves",
            "Repairs: critical hit",
            "Armor bills say hi",
            "Try dodging",
        
        },
    },

    ruRU = {
        GOLD = "золота",
        ON = "ON",
        OFF = "OFF",
        CMD_HELP = "Команды: /tp status | debug on|off | log",
        STATUS_FMT = "статус: debug=%s",
        DEBUG_ON = "debug ON",
        DEBUG_OFF = "debug OFF",
        UNKNOWN_CMD = "Неизвестная команда. /tp help",
        SETTINGS_CATEGORY = "TrashPanda",
        FAST_LOOT_LABEL = "Быстрый сбор добычи",
        LANGUAGE_LABEL = "Язык",
        HUMOR_POS = {
            "Надо больше золота!",
            "Можно строить зиккурат!",
            "Богат как гоблин beach",
            "Время — деньги, дружище",
            "Жадность — это хорошо",
            "Опять золото?",
            "Карман не лопнет?",
            "Звенит слишком тихо",
            "Парни, его карманы блестят!",
            "Хлам готов",
            "Больше монет — меньше мусора",
            "Гоблинская прибыль",
        
        },
        HUMOR_NEG = {
            "Кто-то много огребал...",
            "Хватит танчить лицом",
            "Кливы кушаешь на завтрак?",
            "Ремонт: крит",
            "Счёт за броню пришёл",
            "Пора уклоняться",
        
        },
    },

    deDE = {
        GOLD = "Gold",
        ON = "ON",
        OFF = "OFF",
        CMD_HELP = "Befehle: /tp on | off | status | debug on|off | log",
        ENABLED = "aktiviert",
        DISABLED = "deaktiviert",
        STATUS_FMT = "status: enabled=%s debug=%s",
        DEBUG_ON = "debug ON",
        DEBUG_OFF = "debug OFF",
        UNKNOWN_CMD = "Unbekannter Befehl. /tp help",
        HUMOR_POS = {
            "Mehr Gold!",
            "Du kannst einen Ziggurat bauen!",
            "Reich wie ein Goblin beach",
            "Zeit ist Geld, Freund",
            "Gier ist gut",
            "Schon wieder Gold?",
            "Platzt der Beutel nicht?",
            "Klingt zu leise",
            "Leute, seine Taschen glänzen!",
            "Schrott erledigt",
            "Mehr Münzen, weniger Schrott",
            "Goblin-Gewinn",
        
        },
        HUMOR_NEG = {
            "Da hat jemand kassiert",
            "Hör auf, mit dem Gesicht zu tanken",
            "Cleave zum Frühstück?",
            "Reparatur: Krit",
            "Rüstungsrechnung sagt hallo",
            "Mal ausweichen",
        
        },
    },

    esES = {
        GOLD = "Oro",
        ON = "ON",
        OFF = "OFF",
        CMD_HELP = "Comandos: /tp on | off | status | debug on|off | log",
        ENABLED = "activado",
        DISABLED = "desactivado",
        STATUS_FMT = "estado: enabled=%s debug=%s",
        DEBUG_ON = "debug ON",
        DEBUG_OFF = "debug OFF",
        UNKNOWN_CMD = "Comando desconocido. /tp help",
        HUMOR_POS = {
            "¡Más oro!",
            "¡Ya puedes construir un zigurat!",
            "Rico como un goblin beach",
            "El tiempo es dinero, amigo",
            "La codicia es buena",
            "¿Oro otra vez?",
            "¿No va a reventar la bolsa?",
            "Suena demasiado bajito",
            "¡Chicos, sus bolsillos brillan!",
            "Basura lista",
            "Más monedas, menos chatarra",
            "Ganancia goblin",
        
        },
        HUMOR_NEG = {
            "Alguien se llevó unos golpes...",
            "Deja de tanquear con la cara",
            "¿Cleave de desayuno?",
            "Reparación: crítico",
            "La factura de la armadura llegó",
            "La próxima, esquiva",
        
        },
    },

    -- Same vibe for Latin American Spanish.
    esMX = {},

    zhCN = {
        GOLD = "金币",
        ON = "ON",
        OFF = "OFF",
        CMD_HELP = "命令: /tp on | off | status | debug on|off | log",
        ENABLED = "已开启",
        DISABLED = "已关闭",
        STATUS_FMT = "状态: enabled=%s debug=%s",
        DEBUG_ON = "debug ON",
        DEBUG_OFF = "debug OFF",
        UNKNOWN_CMD = "未知命令. /tp help",
        HUMOR_POS = {
            "还要更多金币！",
            "可以造 Ziggurat 了！",
            "富得像地精 beach",
            "时间就是金钱，朋友",
            "贪婪是好事",
            "又来金币？",
            "口袋不会爆吗？",
            "叮当声太小了",
            "各位，他的口袋在发光！",
            "垃圾搞定",
            "多点金币，少点破烂",
            "地精级收益",
        
        },
        HUMOR_NEG = {
            "有人挨了不少打…",
            "别用脸坦了",
            "把顺劈当早餐？",
            "修理费：暴击",
            "护甲账单来了",
            "下次记得躲",
        
        },
    },

    zhTW = {
        GOLD = "金幣",
        ON = "ON",
        OFF = "OFF",
        CMD_HELP = "命令: /tp on | off | status | debug on|off | log",
        ENABLED = "已開啟",
        DISABLED = "已關閉",
        STATUS_FMT = "狀態: enabled=%s debug=%s",
        DEBUG_ON = "debug ON",
        DEBUG_OFF = "debug OFF",
        UNKNOWN_CMD = "未知命令. /tp help",
        HUMOR_POS = {
            "還要更多金幣！",
            "可以造 Ziggurat 了！",
            "富得像地精 beach",
            "時間就是金錢，朋友",
            "貪婪是好事",
            "又來金幣？",
            "口袋不會爆嗎？",
            "叮噹聲太小了",
            "各位，他的口袋在發光！",
            "垃圾搞定",
            "多點金幣，少點破爛",
            "地精級收益",
        
        },
        HUMOR_NEG = {
            "有人挨了不少打…",
            "別用臉坦了",
            "把順劈當早餐？",
            "修理費：暴擊",
            "護甲帳單來了",
            "下次記得躲",
        
        },
    },
}

-- Inherit esMX from esES if empty.
LOCALES.esMX = LOCALES.esMX and next(LOCALES.esMX) and LOCALES.esMX or LOCALES.esES

local function PickLocale(override)
    local loc = override or (type(GetLocale) == "function" and GetLocale()) or "enUS"
    local L = LOCALES[loc] or LOCALES.enUS
    -- Fallback for missing keys in non-enUS locales
    if loc ~= "enUS" then
        setmetatable(L, { __index = LOCALES.enUS })
    end
    return L
end

TP.L = PickLocale()

function TP:SetLocale(loc)
    self.L = PickLocale(loc)
end

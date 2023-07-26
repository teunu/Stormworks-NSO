local g_savedata =
{
    base_animal_spawn_chance = property.slider("Base animal spawn chance", 0, 1, 0.1, 1.0) * 0.4,
}

local spawncounts = {}

local biomes = {
    arctic = {
        iceberg = {
            low = {
                {c=2000, a={-1}, min=1, max=1}, --none
                {c=1000, a={51}, min=1, max=5}, --penguin
            },
            mid = {
                {c=2000, a={-1}, min=1, max=1}, --none
                {c=1000, a={51}, min=1, max=8}, --penguin
                {c=1000, a={56}, min=1, max=5}, --seal
            },
            high = {
                {c=2000, a={-1}, min=1, max=1}, --none
                {c=1000, a={3}, min=1, max=1}, --bear
                {c=1000, a={51}, min=5, max=8}, --penguin
                {c=1000, a={56}, min=1, max=5}, --seal
            },
        },
        coast = {
            low = {
                {c=2000, a={-1}, min=1, max=1}, --none
                {c=1000, a={51}, min=1, max=5}, --penguin
            },
            mid = {
                {c=2000, a={-1}, min=1, max=1}, --none
                {c=1000, a={51}, min=1, max=8}, --penguin
                {c=1000, a={56}, min=1, max=5}, --seal
            },
            high = {
                {c=2000, a={-1}, min=1, max=1}, --none
                {c=1000, a={51}, min=5, max=8}, --penguin
                {c=1000, a={56}, min=1, max=5}, --seal
                {c=1000, a={61}, min=1, max=5}, --wolf
            }
        },
        forest = {
            low = {
                {c=2000, a={-1}, min=1, max=1}, --none
                {c=1000, a={42}, min=1, max=2}, --hare
            },
            mid = {
                {c=2000, a={-1}, min=1, max=1}, --none
                {c=1000, a={37}, min=1, max=3}, --fox
                {c=1000, a={42}, min=2, max=4}, --hare
            },
            high = {
                {c=2000, a={-1}, min=1, max=1}, --none
                {c=1000, a={37}, min=1, max=3}, --fox
                {c=1000, a={42}, min=2, max=4}, --hare
                {c=1000, a={61}, min=1, max=5}, --wolf
            }
        },
        shelter = {
            low = {
                {c=10000, a={-1}, min=1, max=1}, --none
                {c=1000, a={32}, min=1, max=1}, --siberian_husky,
                {c=1000, a={33}, min=1, max=1}, --st_bernard,
                {c=1000, a={29}, min=1, max=1}, --newfoundland,
                {c=1000, a={25}, min=1, max=1}, --german_shepherd,
            },
            mid = {
                {c=10000, a={-1}, min=1, max=1}, --none
                {c=1000, a={32}, min=1, max=1}, --siberian_husky,
                {c=1000, a={33}, min=1, max=1}, --st_bernard,
                {c=1000, a={29}, min=1, max=1}, --newfoundland,
                {c=1000, a={25}, min=1, max=1}, --german_shepherd,
            },
            high = {
                {c=10000, a={-1}, min=1, max=1}, --none
                {c=1000, a={32}, min=1, max=1}, --siberian_husky,
                {c=1000, a={33}, min=1, max=1}, --st_bernard,
                {c=1000, a={29}, min=1, max=1}, --newfoundland,
                {c=1000, a={25}, min=1, max=1}, --german_shepherd,
            }
        },
        mountain = {
            low = {
                {c=2000, a={-1}, min=1, max=1}, --none
                {c=1000, a={42}, min=1, max=2}, --hare
            },
            mid = {
                {c=2000, a={-1}, min=1, max=1}, --none
                {c=1000, a={42}, min=2, max=4}, --hare
                {c=1000, a={61}, min=1, max=3}, --wolf
            },
            high = {
                {c=2000, a={-1}, min=1, max=1}, --none
                {c=1000, a={61}, min=1, max=5}, --wolf
                {c=1000, a={3}, min=1, max=1}, --bear
                {c=1000, a={42}, min=2, max=4}, --hare
                {c=1, a={13}, min=1, max=1}, --???
            }
        },
        farm = {
            low = {
                {c=2000, a={-1}, min=1, max=1}, --none
                {c=1000, a={38}, min=3, max=6}, --goat
                {c=1000, a={57, 58, 59}, min=3, max=6}, --sheep
                {c=1000, a={10}, min=3, max=6}, --cow
            },
            mid = {
                {c=2000, a={-1}, min=1, max=1}, --none
                {c=1000, a={38}, min=3, max=6}, --goat
                {c=1000, a={57, 58, 59}, min=3, max=6}, --sheep
                {c=1000, a={10}, min=3, max=6}, --cow
            },
            high = {
                {c=2000, a={-1}, min=1, max=1}, --none
                {c=1000, a={38}, min=3, max=6}, --goat
                {c=1000, a={57, 58, 59}, min=3, max=6}, --sheep
                {c=1000, a={10}, min=3, max=6}, --cow
            }
        },
        cave = {
            low = {
                {c=2000, a={-1}, min=1, max=1}, --none
            },
            mid = {
                {c=2000, a={-1}, min=1, max=1}, --none
            },
            high = {
                {c=2000, a={-1}, min=1, max=1}, --none
                {c=1000, a={3}, min=1, max=1}, --bear
            }
        },
        plain = {
            low = {
                {c=2000, a={-1}, min=1, max=1}, --none
                {c=1000, a={42}, min=1, max=2}, --hare
                {c=1000, a={51}, min=1, max=5}, --penguin
            },
            mid = {
                {c=2000, a={-1}, min=1, max=1}, --none
                {c=1000, a={37}, min=1, max=3}, --fox
                {c=1000, a={42}, min=2, max=4}, --hare
                {c=1000, a={51}, min=1, max=8}, --penguin
            },
            high = {
                {c=2000, a={-1}, min=1, max=1}, --none
                {c=1000, a={37}, min=1, max=3}, --fox
                {c=1000, a={42}, min=2, max=4}, --hare
                {c=1000, a={3}, min=1, max=1}, --bear
                {c=1000, a={51}, min=5, max=8}, --penguin
            },
        },
    },
    main = {
        coast = {
            low = {
                {c=2000, a={-1}, min=1, max=1}, --none
            },
            mid = {
                {c=2000, a={-1}, min=1, max=1}, --none
            },
            high = {
                {c=2000, a={-1}, min=1, max=1}, --none
            }
        },
        forest = {
            low = {
                {c=2000, a={-1}, min=1, max=1}, --none
                {c=1000, a={36}, min=1, max=2}, --fox
            },
            mid = {
                {c=2000, a={-1}, min=1, max=1}, --none
                {c=1000, a={0}, min=1, max=3}, --badger
                {c=1000, a={14, 15}, min=1, max=4}, --deer
                {c=1000, a={16, 17}, min=1, max=4}, --deer
                {c=1000, a={36}, min=1, max=4}, --fox
                {c=1000, a={43}, min=1, max=4}, --hare
                {c=1000, a={49, 50}, min=1, max=4}, --muntjac
            },
            high = {
                {c=2000, a={-1}, min=1, max=1}, --none
                {c=1000, a={0}, min=2, max=3}, --badger
                {c=1000, a={14, 15}, min=2, max=5}, --deer
                {c=1000, a={16, 17}, min=2, max=5}, --deer
                {c=1000, a={36}, min=2, max=4}, --fox
                {c=1000, a={43}, min=3, max=5}, --hare
                {c=1000, a={49, 50}, min=3, max=4}, --muntjac
                {c=1000, a={60}, min=1, max=2}, --wildcat
                {c=1000, a={1}, min=1, max=1}, --bear
                {c=1, a={12}, min=1, max=1}, --???
            }
        },
        shelter = {
            low = {
                {c=10000, a={-1}, min=1, max=1}, --none
                {c=1000, a={19}, min=1, max=1}, --border_collie,
                {c=1000, a={20}, min=1, max=1}, --boxer,
                {c=1000, a={23}, min=1, max=1}, --dalmatian,
                {c=1000, a={24}, min=1, max=1}, --dobermann,
                {c=1000, a={26}, min=1, max=1}, --greyhound,
                {c=1000, a={28}, min=1, max=1}, --labrador,
                {c=1000, a={30}, min=1, max=1}, --pug,
                {c=1000, a={35}, min=1, max=1}, --yorkshire_terrier,
            },
            mid = {
                {c=10000, a={-1}, min=1, max=1}, --none
                {c=1000, a={19}, min=1, max=1}, --border_collie,
                {c=1000, a={20}, min=1, max=1}, --boxer,
                {c=1000, a={23}, min=1, max=1}, --dalmatian,
                {c=1000, a={24}, min=1, max=1}, --dobermann,
                {c=1000, a={26}, min=1, max=1}, --greyhound,
                {c=1000, a={28}, min=1, max=1}, --labrador,
                {c=1000, a={30}, min=1, max=1}, --pug,
                {c=1000, a={35}, min=1, max=1}, --yorkshire_terrier,
            },
            high = {
                {c=10000, a={-1}, min=1, max=1}, --none
                {c=1000, a={19}, min=1, max=1}, --border_collie,
                {c=1000, a={20}, min=1, max=1}, --boxer,
                {c=1000, a={23}, min=1, max=1}, --dalmatian,
                {c=1000, a={24}, min=1, max=1}, --dobermann,
                {c=1000, a={26}, min=1, max=1}, --greyhound,
                {c=1000, a={28}, min=1, max=1}, --labrador,
                {c=1000, a={30}, min=1, max=1}, --pug,
                {c=1000, a={35}, min=1, max=1}, --yorkshire_terrier,
            }
        },
        mountain = {
            low = {
                {c=2000, a={-1}, min=1, max=1}, --none
                {c=1000, a={44}, min=2, max=3}, --hare
            },
            mid = {
                {c=2000, a={-1}, min=1, max=1}, --none
                {c=1000, a={44}, min=2, max=4}, --hare
                {c=1000, a={60}, min=1, max=2}, --wildcat
            },
            high = {
                {c=2000, a={-1}, min=1, max=1}, --none
                {c=1000, a={44}, min=2, max=4}, --hare
                {c=1000, a={60}, min=1, max=2}, --wildcat
                {c=1000, a={1}, min=1, max=1}, --bear
            }
        },
        farm = {
            low = {
                {c=2000, a={-1}, min=1, max=1}, --none
                {c=1000, a={8, 11}, min=3, max=6}, --cow
                {c=1000, a={52, 53, 54, 55}, min=3, max=6}, --pig
                {c=1000, a={57, 58, 59}, min=3, max=6}, --sheep
            },
            mid = {
                {c=2000, a={-1}, min=1, max=1}, --none
                {c=1000, a={8, 11}, min=3, max=6}, --cow
                {c=1000, a={52, 53, 54, 55}, min=3, max=6}, --pig
                {c=1000, a={57, 58, 59}, min=3, max=6}, --sheep
            },
            high = {
                {c=2000, a={-1}, min=1, max=1}, --none
                {c=1000, a={8, 11}, min=3, max=6}, --cow
                {c=1000, a={52, 53, 54, 55}, min=3, max=6}, --pig
                {c=1000, a={57, 58, 59}, min=3, max=6}, --sheep
            }
        },
        cave = {
            low = {
                {c=2000, a={-1}, min=1, max=1}, --none
            },
            mid = {
                {c=2000, a={-1}, min=1, max=1}, --none
            },
            high = {
                {c=2000, a={-1}, min=1, max=1}, --none
                {c=1000, a={1}, min=1, max=1}, --bear
            }
        },
        plain = {
            low = {
                {c=2000, a={-1}, min=1, max=1}, --none
                {c=1000, a={45}, min=1, max=2}, --horse
            },
            mid = {
                {c=2000, a={-1}, min=1, max=1}, --none
                {c=1000, a={45}, min=1, max=3}, --horse
            },
            high = {
                {c=2000, a={-1}, min=1, max=1}, --none
                {c=1000, a={45}, min=2, max=4}, --horse
            }
        },
    },
    volcano = {
        coast = {
            low = {
                {c=2000, a={-1}, min=1, max=1}, --none
            },
            mid = {
                {c=2000, a={-1}, min=1, max=1}, --none
            },
            high = {
                {c=2000, a={-1}, min=1, max=1}, --none
            }
        },
        forest = {
            low = {
                {c=2000, a={-1}, min=1, max=1}, --none
            },
            mid = {
                {c=2000, a={-1}, min=1, max=1}, --none
            },
            high = {
                {c=2000, a={-1}, min=1, max=1}, --none
            }
        },
        shelter = {
            low = {
                {c=2000, a={-1}, min=1, max=1}, --none
            },
            mid = {
                {c=2000, a={-1}, min=1, max=1}, --none
            },
            high = {
                {c=2000, a={-1}, min=1, max=1}, --none
            }
        },
        mountain = {
            low = {
                {c=2000, a={-1}, min=1, max=1}, --none
            },
            mid = {
                {c=2000, a={-1}, min=1, max=1}, --none
            },
            high = {
                {c=2000, a={-1}, min=1, max=1}, --none
            }
        },
        farm = {
            low = {
                {c=2000, a={-1}, min=1, max=1}, --none
            },
            mid = {
                {c=2000, a={-1}, min=1, max=1}, --none
            },
            high = {
                {c=2000, a={-1}, min=1, max=1}, --none
            }
        },
        cave = {
            low = {
                {c=2000, a={-1}, min=1, max=1}, --none
            },
            mid = {
                {c=2000, a={-1}, min=1, max=1}, --none
            },
            high = {
                {c=2000, a={-1}, min=1, max=1}, --none
            }
        },
        plain = {
            low = {
                {c=2000, a={-1}, min=1, max=1}, --none
            },
            mid = {
                {c=2000, a={-1}, min=1, max=1}, --none
            },
            high = {
                {c=2000, a={-1}, min=1, max=1}, --none
            }
        },
    },
    arid = {
        coast = {
            low = {
                {c=2000, a={-1}, min=1, max=1}, --none
            },
            mid = {
                {c=2000, a={-1}, min=1, max=1}, --none
                {c=1000, a={43}, min=1, max=3}, --hare
				{c=1000, a={101}, min=1, max=2}, --croc
            },
            high = {
                {c=2000, a={-1}, min=1, max=1}, --none
                {c=1000, a={62}, min=1, max=4}, --wolf
				{c=2000, a={101}, min=2, max=3}, --croc
            }
        },
        forest = {
            low = {
                {c=2000, a={-1}, min=1, max=1}, --none
                {c=1000, a={36}, min=1, max=2}, --fox
                {c=1000, a={43}, min=1, max=3}, --hare
            },
            mid = {
                {c=2000, a={-1}, min=1, max=1}, --none
                {c=1000, a={36}, min=1, max=4}, --fox
                {c=1000, a={43}, min=1, max=4}, --hare
                {c=1000, a={60}, min=1, max=2}, --wildcat
            },
            high = {
                {c=2000, a={-1}, min=1, max=1}, --none
                {c=1000, a={36}, min=2, max=4}, --fox
                {c=1000, a={43}, min=3, max=4}, --hare
                {c=1000, a={60}, min=1, max=2}, --wildcat
                {c=1000, a={62}, min=1, max=4}, --wolf
                {c=1000, a={2}, min=1, max=1}, --bear
            }
        },
        starter = {
            low = {
                {c=1000, a={18}, min=1, max=1}, --beagle,
                {c=1000, a={21}, min=1, max=1}, --corgi,
                {c=1000, a={22}, min=1, max=1}, --dachschund,
                {c=1000, a={27}, min=1, max=1}, --jack_russell,
                {c=1000, a={31}, min=1, max=1}, --shiba,
                {c=1000, a={34}, min=1, max=1}, --vizla,
                {c=1000, a={19}, min=1, max=1}, --border_collie,
                {c=1000, a={20}, min=1, max=1}, --boxer,
                {c=1000, a={23}, min=1, max=1}, --dalmatian,
                {c=1000, a={24}, min=1, max=1}, --dobermann,
                {c=1000, a={26}, min=1, max=1}, --greyhound,
                {c=1000, a={28}, min=1, max=1}, --labrador,
                {c=1000, a={30}, min=1, max=1}, --pug,
                {c=1000, a={35}, min=1, max=1}, --yorkshire_terrier,
            },
            mid = {
                {c=1000, a={18}, min=1, max=1}, --beagle,
                {c=1000, a={21}, min=1, max=1}, --corgi,
                {c=1000, a={22}, min=1, max=1}, --dachschund,
                {c=1000, a={27}, min=1, max=1}, --jack_russell,
                {c=1000, a={31}, min=1, max=1}, --shiba,
                {c=1000, a={34}, min=1, max=1}, --vizla,
                {c=1000, a={19}, min=1, max=1}, --border_collie,
                {c=1000, a={20}, min=1, max=1}, --boxer,
                {c=1000, a={23}, min=1, max=1}, --dalmatian,
                {c=1000, a={24}, min=1, max=1}, --dobermann,
                {c=1000, a={26}, min=1, max=1}, --greyhound,
                {c=1000, a={28}, min=1, max=1}, --labrador,
                {c=1000, a={30}, min=1, max=1}, --pug,
                {c=1000, a={35}, min=1, max=1}, --yorkshire_terrier,
            },
            high = {
                {c=1000, a={18}, min=1, max=1}, --beagle,
                {c=1000, a={21}, min=1, max=1}, --corgi,
                {c=1000, a={22}, min=1, max=1}, --dachschund,
                {c=1000, a={27}, min=1, max=1}, --jack_russell,
                {c=1000, a={31}, min=1, max=1}, --shiba,
                {c=1000, a={34}, min=1, max=1}, --vizla,
                {c=1000, a={19}, min=1, max=1}, --border_collie,
                {c=1000, a={20}, min=1, max=1}, --boxer,
                {c=1000, a={23}, min=1, max=1}, --dalmatian,
                {c=1000, a={24}, min=1, max=1}, --dobermann,
                {c=1000, a={26}, min=1, max=1}, --greyhound,
                {c=1000, a={28}, min=1, max=1}, --labrador,
                {c=1000, a={30}, min=1, max=1}, --pug,
                {c=1000, a={35}, min=1, max=1}, --yorkshire_terrier,
            }
        },
        shelter = {
            low = {
                {c=10000, a={-1}, min=1, max=1}, --none
                {c=1000, a={18}, min=1, max=1}, --beagle,
                {c=1000, a={21}, min=1, max=1}, --corgi,
                {c=1000, a={22}, min=1, max=1}, --dachschund,
                {c=1000, a={27}, min=1, max=1}, --jack_russell,
                {c=1000, a={31}, min=1, max=1}, --shiba,
                {c=1000, a={34}, min=1, max=1}, --vizla,
            },
            mid = {
                {c=10000, a={-1}, min=1, max=1}, --none
                {c=1000, a={18}, min=1, max=1}, --beagle,
                {c=1000, a={21}, min=1, max=1}, --corgi,
                {c=1000, a={22}, min=1, max=1}, --dachschund,
                {c=1000, a={27}, min=1, max=1}, --jack_russell,
                {c=1000, a={31}, min=1, max=1}, --shiba,
                {c=1000, a={34}, min=1, max=1}, --vizla,
            },
            high = {
                {c=10000, a={-1}, min=1, max=1}, --none
                {c=1000, a={18}, min=1, max=1}, --beagle,
                {c=1000, a={21}, min=1, max=1}, --corgi,
                {c=1000, a={22}, min=1, max=1}, --dachschund,
                {c=1000, a={27}, min=1, max=1}, --jack_russell,
                {c=1000, a={31}, min=1, max=1}, --shiba,
                {c=1000, a={34}, min=1, max=1}, --vizla,
            }
        },
        mountain = {
            low = {
                {c=2000, a={-1}, min=1, max=1}, --none
                {c=1000, a={44}, min=2, max=4}, --hare
                {c=2000, a={39, 40, 41}, min=3, max=6}, --goat
                {c=2000, a={98}, min=2, max=4}, --bighorn
            },
            mid = {
                {c=2000, a={-1}, min=1, max=1}, --none
                {c=1000, a={44}, min=2, max=4}, --hare
                {c=1000, a={39, 40, 41}, min=3, max=6}, --goat
                {c=1000, a={62}, min=1, max=4}, --wolf
                {c=2000, a={98}, min=3, max=5}, --bighorn
				{c=2000, a={100}, min=1, max=1}, --mtnlion
            },
            high = {
                {c=2000, a={-1}, min=1, max=1}, --none
                {c=1000, a={44}, min=2, max=4}, --hare
                {c=2000, a={39, 40, 41}, min=3, max=6}, --goat
                {c=1000, a={62}, min=1, max=4}, --wolf
                {c=2000, a={98}, min=3, max=5}, --bighorn
				{c=2000, a={100}, min=1, max=1}, --mtnlion
            }
        },
        farm = {
            low = {
                {c=2000, a={-1}, min=1, max=1}, --none
                {c=1000, a={4, 5, 6, 7}, min=3, max=6}, --chicken
                {c=1000, a={9}, min=3, max=6}, --cow
                {c=1000, a={39, 40, 41}, min=2, max=4}, --goat
                {c=1000, a={53, 54}, min=3, max=6}, --pig
            },
            mid = {
                {c=2000, a={-1}, min=1, max=1}, --none
                {c=1000, a={4, 5, 6, 7}, min=3, max=6}, --chicken
                {c=1000, a={9}, min=3, max=6}, --cow
                {c=1000, a={39, 40, 41}, min=2, max=6}, --goat
                {c=1000, a={53, 54}, min=3, max=6}, --pig
            },
            high = {
                {c=2000, a={-1}, min=1, max=1}, --none
                {c=1000, a={4, 5, 6, 7}, min=3, max=6}, --chicken
                {c=1000, a={9}, min=3, max=6}, --cow
                {c=1000, a={39, 40, 41}, min=3, max=6}, --goat
                {c=1000, a={53, 54}, min=3, max=6}, --pig
            }
        },
        cave = {
            low = {
                {c=2000, a={-1}, min=1, max=1}, --none
            },
            mid = {
                {c=2000, a={-1}, min=1, max=1}, --none
            },
            high = {
                {c=2000, a={-1}, min=1, max=1}, --none
                {c=1000, a={2}, min=1, max=1}, --bear
            }
        },
        plain = {
            low = {
                {c=2000, a={-1}, min=1, max=1}, --none
                {c=1000, a={36}, min=1, max=2}, --fox
                {c=1000, a={43}, min=1, max=3}, --hare
                {c=1000, a={9}, min=1, max=3}, --cow
                {c=1000, a={46, 47, 48}, min=1, max=3}, --horse
                {c=2000, a={97}, min=3, max=6}, --buffalo plains
                {c=2000, a={99}, min=1, max=1}, --roadrunner plains
				{c=2000, a={102}, min=1, max=1}, --coyote plains
            },
            mid = {
                {c=2000, a={-1}, min=1, max=1}, --none
                {c=1000, a={36}, min=1, max=4}, --fox
                {c=1000, a={43}, min=1, max=6}, --hare
                {c=1000, a={60}, min=1, max=6}, --wildcat
                {c=1000, a={9}, min=1, max=6}, --cow
                {c=1000, a={46, 47, 48}, min=2, max=6}, --horse
                {c=2000, a={97}, min=3, max=6}, --buffalo plains
                {c=2000, a={99}, min=1, max=1}, --roadrunner plains
				{c=2000, a={102}, min=1, max=1}, --coyote plains
            },
            high = {
                {c=2000, a={-1}, min=1, max=1}, --none
                {c=1000, a={36}, min=2, max=4}, --fox
                {c=1000, a={43}, min=3, max=8}, --hare
                {c=1000, a={60}, min=1, max=8}, --wildcat
                {c=1000, a={9}, min=3, max=6}, --cow
                {c=1000, a={46, 47, 48}, min=3, max=8}, --horse
                {c=2000, a={97}, min=3, max=6}, --buffalo plains
                {c=2000, a={99}, min=1, max=1}, --roadrunner plains
				{c=2000, a={102}, min=1, max=1}, --coyote plains
            }
        },
    },
}

function onCreate(is_world_create)
	if server.dlcArid() and is_world_create and g_savedata.base_animal_spawn_chance > 0 then
		spawnAll()
	end
end

function spawnAll()
	local spawn_zones = server.getZones("type=animal")

	for _, zone in pairs(spawn_zones) do

        local spawn_chance = math.random()

        local biome = nil
        local habitat = nil
        local density = 0.5

        for _, tag in pairs(zone.tags) do
            if string.find(tag, "biome=") ~= nil then
                biome = string.sub(tag, 7)
            end
            if string.find(tag, "theme=") ~= nil then
                habitat = string.sub(tag, 7)
            end
            if string.find(tag, "density=") ~= nil then
                density = tonumber(string.sub(tag, 9))
            end
        end

        if spawncounts[biome] == nil then spawncounts[biome] = {} end
        if spawncounts[biome][habitat] == nil then spawncounts[biome][habitat] = {zones = 0, total = 0, total_spawned = 0} end
        spawncounts[biome][habitat].zones = spawncounts[biome][habitat].zones + 1

        if spawn_chance <= g_savedata.base_animal_spawn_chance or habitat == "starter" then

            local wild_factor = "low"
            if density > 0.5 then wild_factor = "high"
            elseif density > 0.2 then wild_factor = "mid"
            end

            if biome == nil or habitat == nil or biomes[biome] == nil or biomes[biome][habitat] == nil or biomes[biome][habitat][wild_factor] == nil then
                server.announce("default_creatures", "Error: The script does not contain suitable animals for biome: "..biome.."-"..habitat.."-"..wild_factor)
            else
                local totalChance = 0
                for i = 1, #biomes[biome][habitat][wild_factor] do
                    totalChance = totalChance + biomes[biome][habitat][wild_factor][i].c
                end

                if totalChance == 0 then
                    server.announce("default_creatures", "Error: Could not randomly select suitable animal for biome: "..biome.."-"..habitat.."-"..wild_factor)
                else
                    local rand = math.random(totalChance)

                    local index = -1
                    for i = 1, #biomes[biome][habitat][wild_factor] do
                        if rand <= biomes[biome][habitat][wild_factor][i].c then
                            index = i
                            break
                        else
                            rand = rand - biomes[biome][habitat][wild_factor][i].c
                        end
                    end

                    if index == -1 then
                        -- Didn't spawn animal
                    else
                        local spawn_count = math.random(biomes[biome][habitat][wild_factor][index].min, biomes[biome][habitat][wild_factor][index].max)

                        spawncounts[biome][habitat].total = spawncounts[biome][habitat].total + 1

                        for _ = 1, spawn_count do
                            local animal = biomes[biome][habitat][wild_factor][index].a[math.random(#biomes[biome][habitat][wild_factor][index].a)]

                            if animal ~= -1 then
                                local x = zone.transform[13] - (zone.size.x * 0.5) + (zone.size.x * math.random())
                                local y = zone.transform[14]
                                local z = zone.transform[15] - (zone.size.z * 0.5) + (zone.size.z * math.random())
                                local transform = matrix.translation(x, y, z)
                                local scale = 0.75 + (math.random() * 0.25)
                                server.spawnCreature(transform, animal, scale)

                                spawncounts[biome][habitat].total_spawned = spawncounts[biome][habitat].total_spawned + 1
                            end
                        end
                    end
                end
            end
        end
	end

    for biome in pairs(spawncounts) do
        for habitat in pairs(spawncounts[biome]) do
            server.announce("default_creatures", "spawn counts: "..biome.." - "..habitat.." - "..spawncounts[biome][habitat].total_spawned.." / "..spawncounts[biome][habitat].total.." / "..spawncounts[biome][habitat].zones)
        end
    end
end
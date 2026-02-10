local divine_item = {
  key = "Divine",
  primary_colour = HEX("4F6367"),
  secondary_colour = HEX("000000"),
  loc_txt =  	{
 		name = 'Divine', -- used on card type badges
 		collection = 'Divine Cards', -- label for the button to access the collection
 	},
  collection_row = {6, 6},
  shop_rate = 0,
  default = "c_DF_shaker_pokeball"
}

return {name = "Pokemon Divine Items",
        list = {divine_item}
}
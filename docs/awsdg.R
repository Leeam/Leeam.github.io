mtcars %>%
  rownames_to_column(var = 'model') %>% 
  mutate(Make = word(model, 1)) %>% 
  group_by(Make) %>% 
  summarize(
    `Avg MPG` = round(mean(mpg), 0),
    `Avg HP` = round(mean(hp), 0)
  ) %>% 
  reactable(
    defaultPageSize = 8,
    columns = list(
      `Avg MPG` = colDef(
        cell = icon_assign(., icon = "star", buckets = 5, align_icons = "right")
      ),
      `Avg HP` = colDef(
        cell = icon_assign(., icon = "star", buckets = 5, align_icons = "right")
      )
    )
  ) %>% 
  add_title("MPG & HP Ratings")
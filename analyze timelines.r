local({
suppressPackageStartupMessages({
	library(Cairo)
	library(tidyverse)
})
	
dpi <- 72
	
cancels <- read_csv(
	"analysis/cancels 0-10020.csv",
	col_types = cols(
		slot = col_integer(),
		time = col_integer()))

cancels %>%
	ggplot() +
		geom_density(aes(x=time, y=..scaled..), n=1670, bw=60, fill='black', linetype='blank') +
		scale_x_continuous(limits=c(0, 10020), expand=c(0,0)) +
		theme_void()

ggsave('analysis/cancels.svg', w=1670/dpi, h=256/dpi, dpi=dpi)
})
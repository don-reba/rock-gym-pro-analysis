local({
suppressPackageStartupMessages({
	library(Cairo)
	library(tidyverse)
})
	
dpi <- 72
	
starts <- read_csv("analysis/starts.csv")

occ.sd <- 1
occ <- function(x) {
	starts %>%
		rowwise() %>%
		summarise(pnorm(x, mean=mean(begin, end), sd=occ.sd*(end-begin)), .groups='drop') %>%
		sum / nrow(starts)
}

max <- 180

x <- seq(0, max, length.out=540)
vect <- tibble(x=x, p=Vectorize(occ)(x))

p <- ggplot(vect) +
	scale_x_continuous(limits=c(0, max), breaks=seq(0, max, 30), expand=c(0,0)) +
	scale_y_continuous(limits=c(0, 1), expand=c(0,0)) +
	geom_ribbon(aes(x=x, min=0, max=p), fill='#AC2A0980') +
	theme(axis.text=element_blank(), axis.title=element_blank())

plot(p)

ggsave('analysis/starts.svg', w=1080/dpi, h=512/dpi, dpi=dpi)
})
new_project \
    -name {spi_flash_read} \
    -location {E:\my_work\A3P250\project\RD_FLASH1\designer\impl1\spi_flash_read_fp} \
    -mode {single}
set_programming_file -file {E:\my_work\A3P250\project\RD_FLASH1\designer\impl1\spi_flash_read.pdb}
set_programming_action -action {PROGRAM}
run_selected_actions
save_project
close_project

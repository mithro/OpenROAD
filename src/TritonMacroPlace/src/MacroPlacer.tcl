#############################################################################
##
## Copyright (c) 2019, OpenROAD
## All rights reserved.
##
## BSD 3-Clause License
##
## Redistribution and use in source and binary forms, with or without
## modification, are permitted provided that the following conditions are met:
##
## * Redistributions of source code must retain the above copyright notice, this
##   list of conditions and the following disclaimer.
##
## * Redistributions in binary form must reproduce the above copyright notice,
##   this list of conditions and the following disclaimer in the documentation
##   and/or other materials provided with the distribution.
##
## * Neither the name of the copyright holder nor the names of its
##   contributors may be used to endorse or promote products derived from
##   this software without specific prior written permission.
##
## THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
## AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
## IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
## ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
## LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
## CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
## SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
## INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
## CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
## ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
## POSSIBILITY OF SUCH DAMAGE.
#############################################################################

sta::define_cmd_args "macro_placement" {
  -halo {vertical_width horizontal_width} \
    -channel {vertical_width horizontal_width}\
    [-fence_region {lx ly ux uy}]}

proc macro_placement { args } {
  sta::parse_key_args "macro_placement" args \
    keys {-channel -halo -fence_region -local_config} flags {}

  if { [info exists keys(-halo)] } {
    set halo $keys(-halo)
    if { [llength $halo] != 2 } {
      utl::error "MPL" 92 "-halo is not a list of 2 values."
    }
    lassign $halo halo_x halo_y
    sta::check_positive_float "-halo x" $halo_x
    sta::check_positive_float "-halo y" $halo_y
    mpl::set_halo $halo_x $halo_y
  }

  if { [info exists keys(-channel)] } {
    set channel $keys(-channel)
    if { [llength $channel] != 2 } {
      utl::error "MPL" 93 "-channel is not a list of 2 values."
    }
    lassign $channel channel_x channel_y
    sta::check_positive_float "-channel x" $channel_x
    sta::check_positive_float "-channel y" $channel_y
    mpl::set_channel $channel_x $channel_y
  }

  set block [ord::get_db_block]
  set die_area [$block getDieArea]
  # note that unit is micron
  set dieLx [ord::dbu_to_microns [$die_area xMin]]
  set dieLy [ord::dbu_to_microns [$die_area yMin]]
  set dieUx [ord::dbu_to_microns [$die_area xMax]]
  set dieUy [ord::dbu_to_microns [$die_area yMax]]
  
  if { [info exists keys(-fence_region)] } {
    set fence_region $keys(-fence_region)
    if { [llength $fence_region] != 4 } {
      utl::error "MPL" 94 "-fence_region is not a list of 4 values."
    }
    lassign $fence_region lx ly ux uy 
    
    if { $lx < $dieLx } {
      utl::warn "MPL" 85 "fence_region left x is less than die left x."
      set lx $dieLx
    }
    if { $ly < $dieLy } {
      utl::warn "MPL" 86 "fence_region bottom y is less than die bottom y."
      set ly $dieLy
    }
    if { $ux > $dieUx } {
      utl::warn "MPL" 87 "fence_region right x is greater than die right x."
      set ux $dieUx
    }
    if { $uy > $dieUy } {
      utl::warn "MPL" 88 "fence_region top y is greater than die top y."
      set uy $dieUy
    }
    mpl::set_fence_region $lx $ly $ux $uy
  } else {
    mpl::set_fence_region $dieLx $dieLy $dieUx $dieUy
  }
  
  if { [ord::db_has_rows] } {
    mpl::place_macros
  } else {
    utl::error "MPL" 89 "No rows found. Use initialize_floorplan to add rows."
  }
}

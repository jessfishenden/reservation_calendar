/* Select an entire reservation, for when it spans multiple rows */
function select_reservation(ele, selected) {
  ele = $(ele);
  reservation_id = ele.readAttribute("reservation_id");
  reservations = $$('.reservation_'+reservation_id);
  reservations.each(function(reservation) {
    if (selected) reservation.setStyle({ backgroundColor: '#2EAC6A' });
    else reservation.setStyle({ backgroundColor: ele.readAttribute("color") });
  });
}
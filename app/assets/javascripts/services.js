function update_hours_enabled(i) {
    var enabled = $("input#hours-" + i + "-open").is(":checked");
    $("select#start-hour-" + i).prop('disabled', !enabled);
    $("select#end-hour-" + i).prop('disabled', !enabled);
}

$(document).ready(function() {
    for (var i = 0; i < 7; ++i) (function(i) {
        update_hours_enabled(i);
        $("input.hours-" + i).click(function(e) {
            update_hours_enabled(i);
        });
    })(i);
});

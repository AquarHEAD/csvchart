function make_chart(frame_data, gt_data, rt_data, gpu_data, actor_data, emitter_data, vram_data, audio_data, chart_id, overview_id) {
  var line_option = {show: true, lineWidth: 0.8};

  var dataset = {
    "frame": {data: frame_data, label: "Frame = 0000.00 (ms)", lines: line_option, yaxis: 1},
    "gt": {data: gt_data, label: "GT = 0000.00 (ms)", lines: line_option, yaxis: 1},
    "rt": {data: rt_data, label: "RT = 0000.00 (ms)", lines: line_option, yaxis: 1},
    "gpu": {data: gpu_data, label: "GPU = 0000.00 (ms)", lines: line_option, yaxis: 1},
    "actor": {data: actor_data, label: "Actors = 0000", lines: line_option, yaxis: 2},
    "emitter": {data: emitter_data, label: "Emitters = 000", lines: line_option, yaxis: 3},
    "vram": {data: vram_data, label: "VRAM = 0000.00 (MB)", lines: line_option, yaxis: 4},
    "audio": {data: audio_data, label: "Audio = 0000.00 (ms)", lines: line_option, yaxis: 1},
  }

  var chart_options = {
    legend: {
      position: "ne",
      backgroundColor: "#EAE8FF"
    },
    colors: ["#FE7F2D", "#51A8DD", "#439775", "#CB1B45", "#FEDFE1"],
    yaxis: {
      min: 0
    },
    yaxes: [
      {max: 45},
      {max: 4000},
      {max: 100},
      {max: 1000}
    ],
    crosshair: {
      mode: "x",
      color: "#EAE8FF",
    },
    selection: {
      mode: "x"
    },
    grid: {
      hoverable: true,
      autoHighlight: false,
      backgroundColor: "#222",
      aboveData: false,
      markings: [
        {
          yaxis: {from: 1000/60, to: 1000/60},
          lineWidth: 1,
          color: "#0F0"
        },
        {
          yaxis: {from: 1000/30, to:1000/30},
          lineWidth: 1,
          color: "#FF0"
        }
      ]
    }
  };

  var overview_options = {
    series: {
      lines: {
        show: true,
        lineWidth: 1
      },
      shadowSize: 0
    },
    grid: {
      backgroundColor: "#222"
    },
    colors: ["#FE7F2D", "#51A8DD", "#439775"],
    xaxis: {
      ticks: [],
    },
    yaxis: {
      ticks: [],
      min: 0,
      max: 45,
      autoscaleMargin: 0.1
    },
    selection: {
      mode: "x"
    },
    legend: {
      show: false
    }
  };

  function draw_chart() {
    var data = [];

    // Only add what should be plotted
    $("#choices").find("input:checked").each(function () {
      key = $(this).attr("name");
      if (key && dataset[key]) {
        data.push(dataset[key]);
      }
    });

    $(function(){
      // Plot chart
      var chart = $(chart_id);
      var plot = $.plot(chart_id, data, chart_options);

      function add_fps_label() {
        var pos60 = plot.pointOffset({ x: 0.5, y: 1000/60});
        chart.append('<div style="position:absolute;left:' + (pos60.left + 4) + 'px;top:' + (pos60.top-15) + 'px;color:#0F0;font-size:smaller">60 FPS</div>');

        var pos30 = plot.pointOffset({ x: 0.5, y: 1000/30});
        chart.append('<div style="position:absolute;left:' + (pos30.left + 4) + 'px;top:' + (pos30.top-15) + 'px;color:#FF0;font-size:smaller">30 FPS</div>');
      }

      add_fps_label();

      var overview = $.plot(overview_id, data, overview_options);

      // Bind chart zooming
      $(chart_id).bind("plotselected", function(event, ranges) {
        plot = $.plot(chart_id, data, $.extend(true, {}, chart_options, {
          xaxis: {
            min: ranges.xaxis.from,
            max: ranges.xaxis.to
          }
        }));
        add_fps_label();
        overview.setSelection(ranges, true);
      });

      $(chart_id).bind("plotunselected", function(event, ranges) {
        plot = $.plot(chart_id, data, chart_options);
        add_fps_label();
        overview.clearSelection(true);
      });

      // Bind overview
      $(overview_id).bind("plotselected", function(event, ranges) {
          plot.setSelection(ranges);
      });

      $(overview_id).bind("plotunselected", function(event) {
        plot = $.plot(chart_id, data, chart_options);
        add_fps_label();
        plot.clearSelection(true);
      });

      // Bind events display when hovering
      var updateEventsTimeout = null;
      var latestPosition = null;

      var legends = $(chart_id + " .legendLabel");

      legends.each(function () {
        // fix the widths so they don't jump around
        $(this).css('width', $(this).width());
      });

      function updateEvents() {
        updateEventsTimeout = null;
        var pos = latestPosition;
        var axes = plot.getAxes();
        if (pos.x < axes.xaxis.min || pos.x > axes.xaxis.max ||
          pos.y < axes.yaxis.min || pos.y > axes.yaxis.max) {
          return ;
        }

        // Update values at mouse position
        var i, j, dataset = plot.getData();
        for (i = 0; i < dataset.length; ++i) {

          var series = dataset[i];

          // Find the nearest points, x-wise

          for (j = 0; j < series.data.length; ++j) {
            if (series.data[j][0] > pos.x) {
              break;
            }
          }

          var y,
            p1 = series.data[j - 1],
            p2 = series.data[j];

          if (p1 == null) {
            y = Number(p2[1]);
          } else {
            y = Number(p1[1]);
          }

          if (i == 4 || i == 5) {
            legends.eq(i).text(series.label.replace(/=.*/, "= " + y.toFixed(0)));
          }
          else if (i == 6) {
            legends.eq(i).text(series.label.replace(/=.*/, "= " + y.toFixed(2) + " (MB)"));
          }
          else {
            legends.eq(i).text(series.label.replace(/=.*/, "= " + y.toFixed(2) + " (ms)"));
          }


        }
      }

      $(chart_id).bind("plothover", function(event, pos, item) {
        latestPosition = pos;
        if (!updateEventsTimeout) {
          updateEventsTimeout = setTimeout(updateEvents, 50);
        }
      });

    });
  }

  $("#replot").click(draw_chart);
  draw_chart();
}

Check that everything applied successfully

  $ flight profile list | grep "node00" | grep "complete"
  \xe2\x94\x82 node00 \xe2\x94\x82 master  \xe2\x94\x82 complete \xe2\x94\x82 (esc)
  $ flight profile list | grep "node01" | grep "complete"
  \xe2\x94\x82 node01 \xe2\x94\x82 worker  \xe2\x94\x82 complete \xe2\x94\x82 (esc)

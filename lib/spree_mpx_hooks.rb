class SpreeMpxHooks < Spree::ThemeSupport::HookListener
  insert_after :admin_tabs do
    %(<%= tab(:mpx)  %>)
  end
end

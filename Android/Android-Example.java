package com.waeyaung.waeyaung.activities;

import android.animation.Animator;
import android.animation.AnimatorListenerAdapter;
import android.animation.AnimatorSet;
import android.animation.ObjectAnimator;
import android.content.Intent;
import android.os.Bundle;
import android.support.v4.widget.DrawerLayout;
import android.support.v7.app.ActionBarActivity;
import android.support.v7.widget.Toolbar;
import android.view.Gravity;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;

import com.waeyaung.waeyaung.R;
import com.waeyaung.waeyaung.interfaces.DrawerClosedListener;
import com.waeyaung.waeyaung.utils.WaeYaungApplication;
import com.waeyaung.waeyaung.widget.NavigationDrawerToggle;

public abstract class BaseActivity extends ActionBarActivity {

    private static final long ACCOUNT_BOX_EXPAND_ANIM_DURATION = 100;
    protected Toolbar mActionBarToolbar;
    protected NavigationDrawerToggle mActionBarDrawerToggle;
    protected DrawerLayout mNavDrawerLayout;
    protected static boolean showSplashScreen = true;

    protected static final int NAV_DRAWER_NONE = -1;
    protected static final int NAV_DRAWER_HOME = 0;
    protected static final int NAV_DRAWER_BUY_ITEMS = 1;
    protected static final int NAV_DRAWER_SHOPS = 2;
    protected static final int NAV_DRAWER_CREATE_AD = 3;
    protected static final int NAV_DRAWER_UNPUBLISHED_ADS = 4;
    protected static final int NAV_DRAWER_ABOUT_WAE_YAUNG = 5;
    protected static final int NAV_DRAWER_HELP = 6;
    protected static final int NAV_DRAWER_TERMS = 7;
    protected static final int NAV_DRAWER_SPLASH_SCREEN_ACTIVITY = 8;


    protected boolean mLanguageMenuOpened = false;
    protected TextView mLanguageMenuIndicator;
    protected LinearLayout mLanguageListLayout;
    protected LinearLayout mNavDrawerItemsListLayout;
    protected FrameLayout mMainContentLayout;

    protected final static int[] Languages = new int[]{
            R.string.language_1,
            R.string.language_2,
            R.string.language_3
    };

    protected final static int[] NAV_DRAWER_ICON_RES_ID = new int[]{
            R.drawable.icon_home,
            R.drawable.icon_buy_items,
            R.drawable.icon_shops,
            R.drawable.icon_create_ad,
            R.drawable.icon_unpublished,
            R.drawable.icon_about,
            R.drawable.icon_help,
            R.drawable.icon_about
    };

    protected final static int[] NAV_DRAWER_ICON_SELECTED_RES_ID = new int[]{
            R.drawable.icon_home_selected,
            R.drawable.icon_buy_items_selected,
            R.drawable.icon_shops_selected,
            R.drawable.icon_create_ad_selected,
            R.drawable.icon_unpublished_selected,
            R.drawable.icon_about_selected,
            R.drawable.icon_help_selected,
            R.drawable.icon_about_selected
    };

    protected final static int[] NAV_DRAWER_TITLES_RES_ID = new int[]{
            R.string.nav_drawer_item_home,
            R.string.nav_drawer_item_buy_items,
            R.string.nav_drawer_item_shops,
            R.string.nav_drawer_item_create_ad,
            R.string.nav_drawer_item_unpublished_ads,
            R.string.nav_drawer_item_about_wae_yaung,
            R.string.nav_drawer_item_help,
            R.string.nav_drawer_item_terms
    };

    /**
     * is used to get current nav drawer item
     *
     * @return an int value that is the code for current tab (declared here in base activity)
     */
    protected abstract int getCurrentNavDrawer();

    /**
     * returns resources layout id for current activity
     */
    protected abstract int getCurrentNavDrawerItemContentLayout();


    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.layout_base);

        if (savedInstanceState != null) {
            onPreRestoreSession(savedInstanceState);
        }


        mMainContentLayout = ((FrameLayout) findViewById(R.id.main_content));
        mMainContentLayout.addView(getMainContainer(mMainContentLayout));


        onPreStartActivity();
        initView();
    }

    protected View getMainContainer(ViewGroup container) {
        View view = getLayoutInflater().inflate(getCurrentNavDrawerItemContentLayout(), container, false);
        return view;
    }

    protected void onPreStartActivity() {
    }

    protected Bundle onPreSaveInstanceState(Bundle outState) {
        return outState;
    }

    protected void onPreRestoreSession(Bundle savedInstanceState) {
    }

    @Override
    protected void onSaveInstanceState(Bundle outState) {
        onPreSaveInstanceState(outState);
        super.onSaveInstanceState(outState);
    }

    @Override
    public void setContentView(int layoutResID) {
        super.setContentView(layoutResID);
        getActionBarToolbar();

        if (getCurrentNavDrawer() == NAV_DRAWER_NONE) {
            mNavDrawerLayout.setDrawerLockMode(DrawerLayout.LOCK_MODE_LOCKED_CLOSED);
            getSupportActionBar().setDisplayHomeAsUpEnabled(true);
            getSupportActionBar().setHomeButtonEnabled(true);
        }
    }

    @Override
    protected void onResume() {
        super.onResume();
        if (mNavDrawerLayout != null) {
            if (((WaeYaungApplication) getApplication()).getUsername().equals("")) {
                (findViewById(R.id.tv_log_in)).setVisibility(View.VISIBLE);
                (findViewById(R.id.tv_username_logged)).setVisibility(View.GONE);
            } else {
                (findViewById(R.id.tv_log_in)).setVisibility(View.GONE);
                (findViewById(R.id.tv_username_logged)).setVisibility(View.VISIBLE);
                ((TextView) (findViewById(R.id.tv_username_logged))).setText(((WaeYaungApplication) getApplication()).getUsername());
            }
        }
    }

    protected Toolbar getActionBarToolbar() {
        if (mActionBarToolbar == null) {
            mActionBarToolbar = (Toolbar) findViewById(R.id.toolbar);
            if (mActionBarToolbar != null) {
                setSupportActionBar(mActionBarToolbar);
                mActionBarToolbar.setNavigationIcon(R.drawable.ic_menu);

                if (mNavDrawerLayout == null) {
                    mNavDrawerLayout = (DrawerLayout) findViewById(R.id.drawer_layout);
                    if (mNavDrawerLayout != null) {

                        if (getCurrentNavDrawer() != NAV_DRAWER_NONE) {
                            mActionBarDrawerToggle = new NavigationDrawerToggle(
                                    this,
                                    mNavDrawerLayout,
                                    R.string.navigation_drawer_open,
                                    R.string.navigation_drawer_close);
                            mActionBarDrawerToggle.setDrawerIndicatorEnabled(true);
                            mActionBarDrawerToggle.setDrawerClosedListener(new DrawerClosedListener() {
                                @Override
                                public void onDrawerClosed() {
                                    if (mLanguageMenuIndicator != null) {
                                        mLanguageMenuOpened = !mLanguageMenuOpened;
                                        int hideTranslateY = -mLanguageListLayout.getHeight() / 4;
                                        if (mLanguageMenuOpened && mLanguageListLayout.getTranslationY() == 0) {
                                            // initial setup
                                            mLanguageListLayout.setAlpha(0);
                                            mLanguageListLayout.setTranslationY(hideTranslateY);
                                        }
                                        AnimatorSet set = new AnimatorSet();
                                        set.addListener(new AnimatorListenerAdapter() {
                                            @Override
                                            public void onAnimationEnd(Animator animation) {
                                                mNavDrawerItemsListLayout.setVisibility(mLanguageMenuOpened
                                                        ? View.INVISIBLE : View.VISIBLE);
                                                mLanguageListLayout.setVisibility(mLanguageMenuOpened
                                                        ? View.VISIBLE : View.INVISIBLE);
                                            }

                                            @Override
                                            public void onAnimationCancel(Animator animation) {
                                                onAnimationEnd(animation);
                                            }
                                        });

                                        if (!mLanguageMenuOpened) {
                                            mLanguageMenuIndicator.setCompoundDrawablesWithIntrinsicBounds(null, null, getResources().getDrawable(R.drawable.ic_language_expand), null);
                                            mLanguageMenuIndicator.setText(getResources().getString(R.string.nav_drawer_title_menu_choose_language));
                                            mNavDrawerItemsListLayout.setVisibility(View.VISIBLE);
                                            AnimatorSet subSet = new AnimatorSet();
                                            subSet.playTogether(
                                                    ObjectAnimator.ofFloat(mLanguageListLayout, View.ALPHA, 0)
                                                            .setDuration(ACCOUNT_BOX_EXPAND_ANIM_DURATION),
                                                    ObjectAnimator.ofFloat(mLanguageListLayout, View.TRANSLATION_Y,
                                                            hideTranslateY)
                                                            .setDuration(ACCOUNT_BOX_EXPAND_ANIM_DURATION));
                                            set.playSequentially(
                                                    subSet,
                                                    ObjectAnimator.ofFloat(mNavDrawerItemsListLayout, View.ALPHA, 1)
                                                            .setDuration(ACCOUNT_BOX_EXPAND_ANIM_DURATION));
                                            set.start();
                                        }
                                    }
                                }
                            });
                            mNavDrawerLayout.setDrawerListener(mActionBarDrawerToggle);
                        }
                    }
                }
            }
        }
        return mActionBarToolbar;
    }

    public boolean onCreateDefaultOptionsMenu(Menu menu) {
        getMenuInflater().inflate(R.menu.menu_home, menu);
        return true;
    }

    public boolean onDefaultOptionsItemSelected(MenuItem item) {
        int id = item.getItemId();


        if (mActionBarDrawerToggle != null && mActionBarDrawerToggle.onOptionsItemSelected(item)) {
            return true;
        }
        if (id == R.id.menu_search) {
            startActivity(new Intent(this, SearchResultActivity.class));
            return true;
        }

        return super.onOptionsItemSelected(item);
    }

    protected void initView() {

        if (getCurrentNavDrawer() != NAV_DRAWER_NONE) {
            mLanguageListLayout = (LinearLayout) findViewById(R.id.language_list);
            createLanguageList();

            mNavDrawerItemsListLayout = (LinearLayout) findViewById(R.id.nav_drawer_items_list);
            createMenuItemsList();

            mLanguageMenuIndicator = (TextView) findViewById(R.id.tv_language_menu_indicator);
            if (mLanguageMenuOpened) {
                mLanguageMenuIndicator.setCompoundDrawablesWithIntrinsicBounds(null, null, getResources().getDrawable(R.drawable.ic_language_colapse), null);
                mLanguageMenuIndicator.setText(getResources().getString(R.string.nav_drawer_title_menu_menu));
                mNavDrawerItemsListLayout.setVisibility(View.INVISIBLE);
                mLanguageListLayout.setVisibility(View.VISIBLE);


            } else {
                mLanguageMenuIndicator.setCompoundDrawablesWithIntrinsicBounds(null, null, getResources().getDrawable(R.drawable.ic_language_expand), null);
                mLanguageMenuIndicator.setText(getResources().getString(R.string.nav_drawer_title_menu_choose_language));
                mNavDrawerItemsListLayout.setVisibility(View.VISIBLE);
                mLanguageListLayout.setVisibility(View.INVISIBLE);
            }
        }


    }

    public void onLanguageMenuIndicatorClick(View view) {
        if (mLanguageMenuIndicator != null) {
            mLanguageMenuOpened = !mLanguageMenuOpened;
            int hideTranslateY = -mLanguageListLayout.getHeight() / 4;
            if (mLanguageMenuOpened && mLanguageListLayout.getTranslationY() == 0) {
                // initial setup
                mLanguageListLayout.setAlpha(0);
                mLanguageListLayout.setTranslationY(hideTranslateY);
            }
            AnimatorSet set = new AnimatorSet();
            set.addListener(new AnimatorListenerAdapter() {
                @Override
                public void onAnimationEnd(Animator animation) {
                    mNavDrawerItemsListLayout.setVisibility(mLanguageMenuOpened
                            ? View.INVISIBLE : View.VISIBLE);
                    mLanguageListLayout.setVisibility(mLanguageMenuOpened
                            ? View.VISIBLE : View.INVISIBLE);
                }

                @Override
                public void onAnimationCancel(Animator animation) {
                    onAnimationEnd(animation);
                }
            });

            if (mLanguageMenuOpened) {
                mLanguageMenuIndicator.setCompoundDrawablesWithIntrinsicBounds(null, null, getResources().getDrawable(R.drawable.ic_language_colapse), null);
                mLanguageMenuIndicator.setText(getResources().getString(R.string.nav_drawer_title_menu_menu));


                mLanguageListLayout.setVisibility(View.VISIBLE);
                AnimatorSet subSet = new AnimatorSet();
                subSet.playTogether(
                        ObjectAnimator.ofFloat(mLanguageListLayout, View.ALPHA, 1)
                                .setDuration(ACCOUNT_BOX_EXPAND_ANIM_DURATION),
                        ObjectAnimator.ofFloat(mLanguageListLayout, View.TRANSLATION_Y, 0)
                                .setDuration(ACCOUNT_BOX_EXPAND_ANIM_DURATION));
                set.playSequentially(
                        ObjectAnimator.ofFloat(mNavDrawerItemsListLayout, View.ALPHA, 0)
                                .setDuration(ACCOUNT_BOX_EXPAND_ANIM_DURATION),
                        subSet);
                set.start();
            } else {
                mLanguageMenuIndicator.setCompoundDrawablesWithIntrinsicBounds(null, null, getResources().getDrawable(R.drawable.ic_language_expand), null);
                mLanguageMenuIndicator.setText(getResources().getString(R.string.nav_drawer_title_menu_choose_language));
                mNavDrawerItemsListLayout.setVisibility(View.VISIBLE);
                AnimatorSet subSet = new AnimatorSet();
                subSet.playTogether(
                        ObjectAnimator.ofFloat(mLanguageListLayout, View.ALPHA, 0)
                                .setDuration(ACCOUNT_BOX_EXPAND_ANIM_DURATION),
                        ObjectAnimator.ofFloat(mLanguageListLayout, View.TRANSLATION_Y,
                                hideTranslateY)
                                .setDuration(ACCOUNT_BOX_EXPAND_ANIM_DURATION));
                set.playSequentially(
                        subSet,
                        ObjectAnimator.ofFloat(mNavDrawerItemsListLayout, View.ALPHA, 1)
                                .setDuration(ACCOUNT_BOX_EXPAND_ANIM_DURATION));
                set.start();
            }


        }
    }

    public void createLanguageList() {
        if (mLanguageListLayout == null) {
            return;
        }

        mLanguageListLayout.removeAllViews();

        for (int i = 0; i < Languages.length; i++) {
            if (i != ((WaeYaungApplication) getApplication()).getCurrentLanguage()) {
                mLanguageListLayout.addView(createLanguageListItem(i, mLanguageListLayout, R.drawable.icon_about, Languages[i], false));
            } else {
                mLanguageListLayout.addView(createLanguageListItem(i, mLanguageListLayout, R.drawable.icon_about_selected, Languages[i], true));
            }
        }
    }

    public void createMenuItemsList() {
        if (mNavDrawerItemsListLayout == null) {
            return;
        }

        mNavDrawerItemsListLayout.removeAllViews();
        for (int i = 0; i < NAV_DRAWER_TITLES_RES_ID.length; i++) {
            if (i != getCurrentNavDrawer()) {
                mNavDrawerItemsListLayout.addView(createNavDrawerItem(i, mNavDrawerItemsListLayout, NAV_DRAWER_ICON_RES_ID[i], NAV_DRAWER_TITLES_RES_ID[i], false));
            } else {
                mNavDrawerItemsListLayout.addView(createNavDrawerItem(i, mNavDrawerItemsListLayout, NAV_DRAWER_ICON_SELECTED_RES_ID[i], NAV_DRAWER_TITLES_RES_ID[i], true));
            }
        }
    }

    public View createLanguageListItem(final int itemId, ViewGroup container, int iconResId, int titleResId, boolean selected) {
        View view = getLayoutInflater().inflate(R.layout.layout_nav_drawer_item, container, false);

        TextView tv_title = (TextView) view.findViewById(R.id.tv_language_name);
        ImageView iv_icon = (ImageView) view.findViewById(R.id.iv_language_flag);

        iv_icon.setImageResource(iconResId);
        if (selected) {
            tv_title.setTextColor(getResources().getColor(R.color.selected_text_color));
        } else {
            tv_title.setTextColor(getResources().getColor(R.color.default_text_color));
        }
        tv_title.setText(getResources().getString(titleResId));

        view.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                onLanguageListItemClick(itemId);
            }
        });

        return view;
    }

    public View createNavDrawerItem(final int itemId, ViewGroup container, int iconResId, int titleResId, boolean selected) {
        View view = getLayoutInflater().inflate(R.layout.layout_nav_drawer_item, container, false);

        TextView tv_title = (TextView) view.findViewById(R.id.tv_language_name);
        ImageView iv_icon = (ImageView) view.findViewById(R.id.iv_language_flag);

        iv_icon.setImageResource(iconResId);
        if (selected) {
            tv_title.setTextColor(getResources().getColor(R.color.selected_text_color));
        } else {
            tv_title.setTextColor(getResources().getColor(R.color.default_text_color));
        }
        tv_title.setText(getResources().getString(titleResId));

        view.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                onNavDrawerItemClicked(itemId);
            }
        });

        return view;
    }

    public void onNavDrawerItemClicked(final int itemId) {
        if (itemId == getCurrentNavDrawer()) {
            mNavDrawerLayout.closeDrawer(Gravity.START);
            return;
        }

        goToNavDrawerItem(itemId);
    }

    public void goToNavDrawerItem(final int itemId) {

        if (mNavDrawerLayout.isDrawerOpen(Gravity.START)) {
            mNavDrawerLayout.closeDrawer(Gravity.START);
        }

        Intent intent = null;
        switch (itemId) {
            case NAV_DRAWER_HOME:
                intent = new Intent(this, HomeActivity.class);

                break;
            case NAV_DRAWER_BUY_ITEMS:
                intent = new Intent(this, BuyItemsActivity.class);

                break;
            case NAV_DRAWER_SHOPS:
                intent = new Intent(this, ShopsActivity.class);

                break;
            case NAV_DRAWER_CREATE_AD:
                intent = new Intent(this, CreateAdActivity.class);

                break;
            case NAV_DRAWER_UNPUBLISHED_ADS:
                intent = new Intent(this, UnpublishedAdsActivity.class);

                break;
            case NAV_DRAWER_ABOUT_WAE_YAUNG:
                intent = new Intent(this, AboutActivity.class);

                break;
            case NAV_DRAWER_HELP:
                intent = new Intent(this, HelpActivity.class);

                break;
            case NAV_DRAWER_TERMS:
                intent = new Intent(this, TermsConditionsActivity.class);

                break;

        }

        if (intent != null) {
            startActivity(intent);
//            overridePendingTransition(0,0);
            finish();
        }
    }

    public void onLanguageListItemClick(final int itemId) {
        //  todo : change language
        Toast.makeText(this, getString(Languages[itemId]) + "Selected", Toast.LENGTH_SHORT).show();
    }


    public void onLogInClick(View view) {
        startActivity(new Intent(this, LoginActivity.class));
    }

    @Override
    protected void onPause() {
        super.onPause();
        if (mNavDrawerLayout != null) {
            if (mNavDrawerLayout.isDrawerOpen(Gravity.START)) {
                mNavDrawerLayout.closeDrawer(Gravity.START);
            }
        }
    }

    public void createAdClick(View view) {
        goToNavDrawerItem(NAV_DRAWER_CREATE_AD);
    }

    public void onUserNameClick(View view) {
        ((WaeYaungApplication) getApplication()).setUsername("");
        (findViewById(R.id.tv_log_in)).setVisibility(View.VISIBLE);
        (findViewById(R.id.tv_username_logged)).setVisibility(View.GONE);
    }
}

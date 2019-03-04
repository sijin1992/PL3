package org.PayPlugin;

import java.util.Arrays;
import java.util.List;
import java.util.Map;

import org.cocos2dx.lib.Cocos2dxGLSurfaceView;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;
import org.json.JSONStringer;

import com.googlesdk.iab.util.SkuDetails;
import com.googlesdk.iab.util.Inventory;
import com.googlesdk.iab.util.Purchase;
import com.googlesdk.iab.util.IabHelper;
import com.googlesdk.iab.util.IabResult;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.Intent;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.ImageView;

import com.adjust.sdk.Adjust;
import com.adjust.sdk.AdjustEvent;

import com.gameanalytics.sdk.*;

public class GooglePlayIABPlugin
{
	public static final String TAG = "GooglePlayIABPlugin";
	private static GooglePlayIABPlugin sInstance;
	private Activity mActivity;
	IabHelper mHelper;
	Inventory mInventory = null;

	// (arbitrary) request code for the purchase flow
	static final int RC_REQUEST = 10001;	
	
	public GooglePlayIABPlugin(Activity activity) {
		this.mActivity = activity;
		sInstance = this;
	}

	// updates UI to reflect model
	public void updateUi() {
	}
	
	// Enables or disables the "please wait" screen.
	void setWaitScreen(boolean set) {
//       findViewById(R.id.screen_main).setVisibility(set ? View.GONE : View.VISIBLE);
//       findViewById(R.id.screen_wait).setVisibility(set ? View.VISIBLE : View.GONE);
	}

	void complain(String message) {
		Log.e(TAG, "**** Error: " + message);
//		alert("Error: " + message);
	}

	void alert(String message) {
		AlertDialog.Builder bld = new AlertDialog.Builder(mActivity);
		bld.setMessage(message);
		bld.setNeutralButton("OK", null);
		Log.d(TAG, "Showing alert dialog: " + message);
		bld.create().show();
	}	
	
	public void onCreate(Bundle savedInstanceState) {
		String base64EncodedPublicKey = "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAmvIWzr0wfeitcvD+BYg8GX11JJ5NNwu6pgd5qw7OTxiyxcveYE9qT47hcUhBaCC6DpYO//jAw6Z8b9zTUGOALstCnjON6GERVNAMc/me5p6nczvgMq/xkyLhAZY8m99LnpAIjKwO0xyyr5ptKyjH1gDAUtJPfg6yivciwco2Zn1+cOJgn/+iRS8hJtRm6j2xGIvjk18jsoi1eVm5nMBDtIBx0XXhM2CnqawDteZDzPLppTkhcJIOLsJzHvdY0y4ZYWvZ+hK8VUiWC8vBBpg3hD426XflKSDwAxZ197gj5d7pC2eo19iwvp8pjxOuhi/rCY9qa+Hi5aQq4LGP/6qdMwIDAQAB";
		// Create the helper, passing it our context and the public key to verify signatures with
		Log.d(TAG, "Creating IAB helper.");
		mHelper = new IabHelper(mActivity, base64EncodedPublicKey);

		// enable debug logging (for a production application, you should set this to false).
		mHelper.enableDebugLogging(true);

		// Start setup. This is asynchronous and the specified listener
		// will be called once setup completes.
		Log.d(TAG, "Starting setup.");
		mHelper.startSetup(new IabHelper.OnIabSetupFinishedListener() {
			public void onIabSetupFinished(IabResult result) {
				Log.d(TAG, "Setup finished.");

				if (!result.isSuccess()) {
					// Oh noes, there was a problem.
					complain("Problem setting up in-app billing: " + result);
					return;
				}

				// Have we been disposed of in the meantime? If so, quit.
				if (mHelper == null) return;

				// IAB is fully set up. 
				Log.d(TAG, "Setup successful. ");
			}
		});
	}

	public static void ReqItemInfo(final String strItemTypeIdSet) {
		sInstance.mActivity.runOnUiThread(new Runnable() {
			public void run() {
				List<String> lstStrTypeId = java.util.Arrays.asList(strItemTypeIdSet.split(" "));
				Log.d(TAG, "Querying inventory.");
				try {
					sInstance.mHelper.queryInventoryAsync(true, lstStrTypeId,
							sInstance.mGotInventoryListener);
				} catch (Exception e) {
					Log.e(TAG, "Querying inventory Error.");
				}
			}
		});
	}

	private String inventoryToSkuJson(Inventory inventory) throws JSONException {
		JSONArray jsonSkuDetail = new JSONArray();
		for (Map.Entry<String, SkuDetails> entry : inventory.mSkuMap.entrySet()) {
			jsonSkuDetail.put(entry.getValue().getJson());
		}
		return jsonSkuDetail.toString();
	}
	
	
	// Listener that's called when we finish querying the items and subscriptions we own
	IabHelper.QueryInventoryFinishedListener mGotInventoryListener = new IabHelper.QueryInventoryFinishedListener() {
		public void onQueryInventoryFinished(IabResult result, Inventory inventory) {
			Log.d(TAG, "Query inventory finished.");

			// Have we been disposed of in the meantime? If so, quit.
			if (mHelper == null) return;

			// Is it a failure?
			if (result.isFailure()) {
				complain("Failed to query inventory: " + result);
				return;
			}            

			Log.d(TAG, "Query inventory was successful.");
			mInventory = new Inventory();
			mInventory.mSkuMap.putAll(inventory.mSkuMap);
			mInventory.mPurchaseMap.putAll(inventory.mPurchaseMap);

			/*
			 * Check for items we own. Notice that for each purchase, we check
			 * the developer payload to see if it's correct! See
			 * verifyDeveloperPayload().
			 */

			try {
				String strJsonSkuDetail = inventoryToSkuJson(inventory);
				runNativeOnReceiveItemInfo(strJsonSkuDetail);
				Log.d(TAG, "strJsonSkuDetail: " + strJsonSkuDetail);
			} catch (JSONException e) {
				Log.d(TAG, "Couldn't serialize the inventory");
			}

			updateUi();
			setWaitScreen(false);
			Log.d(TAG, "Initial inventory query finished; enabling main UI.");

			for (Map.Entry<String,Purchase> entry : inventory.mPurchaseMap.entrySet()) {
				runNativeOnRestore(entry.getValue().getOriginalJson(), entry.getValue().getSignature());
			}
		}
	};
	
	public static void PayStart(final String strItemTypeId, final String strExtraVerifyInfo) {
		sInstance.mActivity.runOnUiThread(new Runnable() {
			public void run() {
				Log.d(TAG, "PayStart " + strItemTypeId + " Extra " + strExtraVerifyInfo);
				try {
					sInstance.mHelper.launchPurchaseFlow(sInstance.mActivity, strItemTypeId, RC_REQUEST,
							sInstance.mPurchaseFinishedListener, strExtraVerifyInfo);
				} catch (Exception e) {
					e.printStackTrace();
				}
			}
		});
	}

	public static void PayEnd(final String strItemKey, final double cost, final int result) {
		sInstance.mActivity.runOnUiThread(new Runnable() {
			public void run() {
				Log.d(TAG, "PayEnd " + strItemKey);
				if (sInstance.mInventory == null) {
					sInstance.complain("PayEnd mInventory is null");
					return;
				}

				Purchase purchase = sInstance.mInventory.getPurchase(strItemKey);
				if (purchase != null) {
					try {
						sInstance.mHelper.consumeAsync(purchase, sInstance.mConsumeFinishedListener);

						if(result==1) {

						}

					} catch (Exception e) {
						e.printStackTrace();
					}
				} else {
					sInstance.complain("PayEnd " + strItemKey + " purchase not found");
				}
			}
		});
	}

    public static void onPurchaseEvent(final String strItemKey, final double cost){
        sInstance.mActivity.runOnUiThread(new Runnable() {
            public void run() {

                if (sInstance.mInventory == null) {
                    sInstance.complain("onPurchaseEvent mInventory is null");
                    return;
                }

                Purchase purchase = sInstance.mInventory.getPurchase(strItemKey);

                AdjustEvent event = new AdjustEvent("jc4hsb");
                event.setRevenue(cost, "USD");
                Adjust.trackEvent(event);

                int gb_cost = (int)cost*100;
                GameAnalytics.addBusinessEventWithCurrency("USD", gb_cost, "", "", "", "", "google_play", "");

            }
        });
    }
	
	public void onDestroy() {
		// very important:
		Log.d(TAG, "Destroying helper.");
		if (mHelper != null) {
			mHelper.dispose();
			mHelper = null;
		}
	}

	public boolean handleActivityResult(int requestCode, int resultCode, Intent data) {
		return mHelper.handleActivityResult(requestCode, resultCode, data);
	}

	/** Verifies the developer payload of a purchase. */
	boolean verifyDeveloperPayload(Purchase p) {
		String payload = p.getDeveloperPayload();

		/*
		 * TODO: verify that the developer payload of the purchase is correct. It will be
		 * the same one that you sent when initiating the purchase.
		 *
		 * WARNING: Locally generating a random string when starting a purchase and
		 * verifying it here might seem like a good approach, but this will fail in the
		 * case where the user purchases an item on one device and then uses your app on
		 * a different device, because on the other device you will not have access to the
		 * random string you originally generated.
		 *
		 * So a good developer payload has these characteristics:
		 *
		 * 1. If two different users purchase an item, the payload is different between them,
		 *    so that one user's purchase can't be replayed to another user.
		 *
		 * 2. The payload must be such that you can verify it even when the app wasn't the
		 *    one who initiated the purchase flow (so that items purchased by the user on
		 *    one device work on other devices owned by the user).
		 *
		 * Using your own server to store and verify developer payloads across app
		 * installations is recommended.
		 */

		return true;
	}

	// Callback for when a purchase is finished
	IabHelper.OnIabPurchaseFinishedListener mPurchaseFinishedListener = new IabHelper.OnIabPurchaseFinishedListener() {
		public void onIabPurchaseFinished(IabResult result, Purchase purchase) {
			Log.d(TAG, "Purchase finished: " + result + ", purchase: " + purchase);

			// if we were disposed of in the meantime, quit.
			if (mHelper == null) return;

			if (result.isFailure()) {
				complain("Error purchasing: " + result);
                runNativeOnFailed("null",""+result);
				setWaitScreen(false);
				return;
			}
			if (!verifyDeveloperPayload(purchase)) {
				complain("Error purchasing. Authenticity verification failed.");
                runNativeOnFailed("null","Authenticity verification failed.");
				setWaitScreen(false);
				return;
			}

			Log.d(TAG, "Purchase successful.");
			if (sInstance.mInventory != null) {
				sInstance.mInventory.addPurchase(purchase);  	
			}

			runNativeOnPurchased(purchase.getOriginalJson(), purchase.getSignature());
		}
	};

	// Called when consumption is complete
	IabHelper.OnConsumeFinishedListener mConsumeFinishedListener = new IabHelper.OnConsumeFinishedListener() {
		public void onConsumeFinished(Purchase purchase, IabResult result) {
			Log.d(TAG, "Consumption finished: " + result);// + ", purchase: " + purchase);

			// if we were disposed of in the meantime, quit.
			if (mHelper == null) return;

			// We know this is the "gas" sku because it's the only one we consume,
			// so we don't check which sku was consumed. If you have more than one
			// sku, you probably should check...
			if (result.isSuccess()) {
				// successfully consumed, so we apply the effects of the item in our
				// game world's logic, which in our case means filling the gas tank a bit
				Log.d(TAG, "Consumption successful. Provisioning.");
			}
			else {
				complain("Error while consuming: " + result);
			}
			updateUi();
			setWaitScreen(false);
			Log.d(TAG, "End consumption flow.");
		}
	};	

	public static native void nativeOnReceiveItemInfo(String strJsonSkuDetail);
	public static native void nativeOnPurchased(String strJsonPurchaseInfo, String strSignature);
	public static native void nativeOnFailed(String strItemKey, String strInfo);
	public static native void nativeOnRestore(String strJsonPurchaseInfo, String strSignature);

	public static void runNativeOnReceiveItemInfo(final String strJsonSkuDetail) {
		Cocos2dxGLSurfaceView.getInstance().queueEvent(new Runnable() {
			public void run() {
				nativeOnReceiveItemInfo(strJsonSkuDetail);
			} 
		});
	}
	
	public static void runNativeOnPurchased(final String strJsonPurchaseInfo, final String strSignature) {
		Cocos2dxGLSurfaceView.getInstance().queueEvent(new Runnable() {
			public void run() {
				nativeOnPurchased(strJsonPurchaseInfo, strSignature);
			} 
		});
	}

	public static void runNativeOnFailed(final String strItemKey, final String strInfo) {
		Cocos2dxGLSurfaceView.getInstance().queueEvent(new Runnable() {
			public void run() {
				nativeOnFailed(strItemKey, strInfo);
			} 
		});
	}

	public static void runNativeOnRestore(final String strJsonPurchaseInfo, final String strSignature) {
		Cocos2dxGLSurfaceView.getInstance().queueEvent(new Runnable() {
			public void run() {
				nativeOnRestore(strJsonPurchaseInfo, strSignature);
			} 
		});
	}
}

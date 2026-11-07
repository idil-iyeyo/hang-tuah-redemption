package com.godot.game.hms;

import android.app.Activity;
import android.content.Intent;
import android.util.Log;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.huawei.hmf.tasks.OnFailureListener;
import com.huawei.hmf.tasks.OnSuccessListener;
import com.huawei.hmf.tasks.Task;
import com.huawei.hms.support.account.AccountAuthManager;
import com.huawei.hms.support.account.request.AccountAuthParams;
import com.huawei.hms.support.account.request.AccountAuthParamsHelper;
import com.huawei.hms.support.account.result.AuthAccount;
import com.huawei.hms.support.account.service.AccountAuthService;

import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.SignalInfo;
import org.godotengine.godot.plugin.UsedByGodot;

import java.util.HashSet;
import java.util.Set;

/**
 * Godot 4 Android Plugin bridging Huawei Mobile Services (HMS) Account Kit.
 * Handles Silent Sign-In, Interactive Sign-In, and Sign-Out.
 */
public class HMSAccountPlugin extends GodotPlugin {
    private static final String TAG = "HMSAccountPlugin";
    private static final int REQUEST_CODE_SIGN_IN = 8888;

    private AccountAuthService mAuthService;

    public HMSAccountPlugin(Godot godot) {
        super(godot);
    }

    @NonNull
    @Override
    public String getPluginName() {
        return "HMSAccountPlugin";
    }

    @NonNull
    @Override
    public Set<SignalInfo> getPluginSignals() {
        Set<SignalInfo> signals = new HashSet<>();
        signals.add(new SignalInfo("sign_in_success", String.class, String.class));
        signals.add(new SignalInfo("sign_in_failed", Integer.class, String.class));
        signals.add(new SignalInfo("sign_out_success"));
        return signals;
    }

    private AccountAuthService getAuthService() {
        if (mAuthService == null) {
            AccountAuthParams authParams = new AccountAuthParamsHelper(AccountAuthParams.DEFAULT_AUTH_REQUEST_PARAM)
                    .setId()
                    .setProfile()
                    .createParams();
            Activity activity = getActivity();
            if (activity != null) {
                mAuthService = AccountAuthManager.getService(activity, authParams);
            }
        }
        return mAuthService;
    }

    @UsedByGodot
    public void silentSignIn() {
        final AccountAuthService service = getAuthService();
        if (service == null) {
            emitSignal("sign_in_failed", -1, "Activity or AuthService unavailable");
            return;
        }

        Task<AuthAccount> task = service.silentSignIn();
        task.addOnSuccessListener(new OnSuccessListener<AuthAccount>() {
            @Override
            public void onSuccess(AuthAccount authAccount) {
                String displayName = authAccount.getDisplayName();
                String openId = authAccount.getOpenId();
                Log.i(TAG, "Silent sign-in successful: " + displayName);
                emitSignal("sign_in_success", displayName != null ? displayName : "Pilot", openId != null ? openId : "");
            }
        });
        task.addOnFailureListener(new OnFailureListener() {
            @Override
            public void onFailure(Exception e) {
                Log.w(TAG, "Silent sign-in failed, requires interactive sign-in: " + e.getMessage());
                emitSignal("sign_in_failed", -2, e.getMessage() != null ? e.getMessage() : "Silent sign-in failed");
            }
        });
    }

    @UsedByGodot
    public void signIn() {
        final AccountAuthService service = getAuthService();
        final Activity activity = getActivity();
        if (service == null || activity == null) {
            emitSignal("sign_in_failed", -1, "Activity or AuthService unavailable");
            return;
        }

        activity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                try {
                    Intent signInIntent = service.getSignInIntent();
                    activity.startActivityForResult(signInIntent, REQUEST_CODE_SIGN_IN);
                } catch (Exception e) {
                    Log.e(TAG, "Failed to start sign in intent: " + e.getMessage());
                    emitSignal("sign_in_failed", -3, e.getMessage());
                }
            }
        });
    }

    @UsedByGodot
    public void signOut() {
        final AccountAuthService service = getAuthService();
        if (service == null) {
            emitSignal("sign_out_success");
            return;
        }

        Task<Void> signOutTask = service.signOut();
        signOutTask.addOnSuccessListener(new OnSuccessListener<Void>() {
            @Override
            public void onSuccess(Void aVoid) {
                Log.i(TAG, "Sign out successful");
                emitSignal("sign_out_success");
            }
        });
        signOutTask.addOnFailureListener(new OnFailureListener() {
            @Override
            public void onFailure(Exception e) {
                Log.w(TAG, "Sign out error, forcing local sign out: " + e.getMessage());
                emitSignal("sign_out_success");
            }
        });
    }

    @Override
    public void onMainActivityResult(int requestCode, int resultCode, @Nullable Intent data) {
        super.onMainActivityResult(requestCode, resultCode, data);
        if (requestCode == REQUEST_CODE_SIGN_IN) {
            Task<AuthAccount> authAccountTask = AccountAuthManager.parseAuthResultFromIntent(data);
            if (authAccountTask.isSuccessful()) {
                AuthAccount authAccount = authAccountTask.getResult();
                String displayName = authAccount.getDisplayName();
                String openId = authAccount.getOpenId();
                Log.i(TAG, "Interactive sign-in successful: " + displayName);
                emitSignal("sign_in_success", displayName != null ? displayName : "Pilot", openId != null ? openId : "");
            } else {
                Exception e = authAccountTask.getException();
                String errorMsg = e != null ? e.getMessage() : "Sign-in intent canceled or failed";
                Log.e(TAG, "Interactive sign-in failed: " + errorMsg);
                emitSignal("sign_in_failed", resultCode, errorMsg);
            }
        }
    }
}
